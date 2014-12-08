/* 画面遷移のエフェクト */

// JavaScriptモードだとENUMが使えない。かなしい。
final int DIRECTION_LEFT  = 0;
final int DIRECTION_RIGHT = 1;
final int DIRECTION_UP    = 2;
final int DIRECTION_DOWN  = 3;

abstract class Transition {
  protected PImage prev;
  protected PImage next;
  protected long   counter;
  protected int    direction;
  protected Transition() {}
  
  Transition(PImage img1, PImage img2, int dir) {    
    prev      = img1;
    next      = img2;
    direction = dir;
    counter   = 0;
  }

}

int g_Direction;
class Mosaic extends Transition implements State {
  final float SPEED = 0.05;
  Mosaic(PImage img1, PImage img2, int direction) {
    super(img1, img2, direction);
  }
  
  State update() {
    camera();
    pushMatrix();
    drawBackground(next);    
    
    float xCoef = direction == DIRECTION_LEFT  ? -1 : 
                  direction == DIRECTION_RIGHT ?  1 : 0;
    float zCoef = direction == DIRECTION_UP    ? -1 :
                  direction == DIRECTION_DOWN  ?  1 : 0;
    translate(xCoef * SPEED * pow(counter, 3), zCoef * SPEED * pow(counter, 3), 0);  

    
    drawDividedImage(this.prev, 20, 20);
    popMatrix();

    return ++counter < 60 ? this : 
      ++g_Direction % 4 != 0 ?
        new Mosaic(next, prev, g_Direction % 4) : new Mosaic2(next, prev, g_Direction % 4);
  }
}

class Mosaic2 extends Transition implements State {
  final float SPEED = 0.5;
  final float ROTATE_SPEED = 0.025;
  long zoomCounter;
  Mosaic2(PImage img1, PImage img2, int direction) {
    super(img1, img2, direction);
    zoomCounter = 1;
  }
  
  State update() {
    camera();
    pushMatrix();
    
    drawBackground(next);
    
    float angle = radians(ROTATE_SPEED * pow(++counter, 2));
    
    float angleSign = (direction == DIRECTION_LEFT || direction == DIRECTION_DOWN) ? -1: 1;

    translate(0, 0, SPEED * pow(++zoomCounter, 2));
    translate(0.5 * width, 0.5*height, -500);
    

    if (direction == DIRECTION_LEFT || direction == DIRECTION_RIGHT) {
      rotateY(angleSign * angle);      
    } else if(direction == DIRECTION_UP || direction == DIRECTION_DOWN) {
      rotateX(angleSign * angle);
    }
    

    translate(-0.5 * width, -0.5*height, 500);

    drawDividedImage(prev, 20, 20);
    
    popMatrix();

    return angle < HALF_PI ? this : 
      ++g_Direction % 4 != 0 ?
        new Mosaic2(next, prev, g_Direction % 4) : new Mosaic(next, prev, g_Direction % 4);
    
  }
}

void drawDividedImage(PImage image,
                      int numVerticalFractions, 
                      int numHorizontalFractions) 
{
  if(image.get(0, 0) == 0) return;
  
  randomSeed(0);
  
  float verticalSize   = (float)height / numVerticalFractions;
  float horizontalSize = (float)width  / numHorizontalFractions;

  noStroke();
  for(int i = 0; i < numVerticalFractions; ++i) {
    for(int j = 0; j < numVerticalFractions; ++j) {
      float x = i * horizontalSize;
      float y = j * verticalSize;
      drawFraction(image, x, y, horizontalSize, verticalSize, random(FAR_CLIP - 1));
    }
  }             
}

// 遠クリップ面上に画像を描画するよ
void drawBackground(PImage img) {
  drawFraction(img, 0, 0, img.width, img.height, FAR_CLIP);
}

void drawFraction(PImage image,           // テクスチャ
                  float projectedX,       // 始点x座標
                  float projectedY,       // 始点y座標
                  float projectedWidth,   // 幅
                  float projectedHeight,  // 高さ
                  float depth)            // 奥行き
{
  if(image.get(0, 0) == 0) return;
  pushMatrix();
  
  // 四角形の頂点数
  final int NUM_VERTICES = 4;
  
  // 画面サイズの半分
  final float HALF_WIDTH  = 0.5 * width;
  final float HALF_HEIGHT = 0.5 * height;

  // カメラ焦点距離
  final float FOCAL_LENGTH = HALF_HEIGHT / tan(PI / 6.0);

  // 遠クリップ面のz座標の絶対値
  final float ABS_DEPTH = abs(depth);
  
  // カメラ視点から遠クリップ面までの距離
  final float FAR_DISTANCE = ABS_DEPTH + FOCAL_LENGTH;
  
  final PVector[] coords = new PVector[] {
    new PVector(projectedX                 , projectedY                  , 0),
    new PVector(projectedX                 , projectedY + projectedHeight, 0),
    new PVector(projectedX + projectedWidth, projectedY + projectedHeight, 0),
    new PVector(projectedX + projectedWidth, projectedY                  , 0)
  };
  
  beginShape();
  texture(image);
  
  for(int i = 0; i < NUM_VERTICES; ++i) {
    float x = HALF_WIDTH + (coords[i].x - HALF_WIDTH)   * FAR_DISTANCE / FOCAL_LENGTH;
    float y = HALF_HEIGHT + (coords[i].y - HALF_HEIGHT) * FAR_DISTANCE / FOCAL_LENGTH;
    float z = -ABS_DEPTH;
    
    float u = coords[i].x;
    float v = coords[i].y;
    vertex(x, y, z, u, v);
  }
  
  endShape(CLOSE);
  popMatrix();
}
