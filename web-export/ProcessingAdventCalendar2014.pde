PImage  img;
TypeWriter typeWriter;

State state;
void setup() {
  size(400, 300, P3D);
  frameRate(20);
  
  typeWriter = new Typer();
  setupTypeWriter();
  
  img = loadImage("bg.png");  
  state = new Boid();
}

void draw() {
  if(img.get(0, 0) == 0) return;

  background(0);

  state = state.update();
  typeWriter = typeWriter.update();
  /*
  pushMatrix();
  camera(500, 500, 500, 0, 0, 0, 0, -1, 0);
  rotateY(radians(frameCount));
  
  fill(255);
  noStroke();
  origami = origami.update();
  
  typeWriter = typeWriter.update();
  popMatrix();
  */
}
/* Flocking */

final float TIMESTEP               = 0.001f;
final float THRUSTFACTOR           = 3;
final boolean CHASESETUP           = true;
final int SPAWN_AREA_R             = 100;
 
final int MAX_NUM_UNITS            = 20;
final int UNIT_LENGTH              = 10;
final int OBSTACLE_RADIUS_FACTOR   = 2;
final int OBSTACLE_RADIUS          = OBSTACLE_RADIUS_FACTOR * UNIT_LENGTH;
final int COLLISION_VISIBILITY_FACTOR = 25;
 
final int WIDEVIEW_RADIUS_FACTOR    = 200;
final int NARROWVIEW_RADIUS_FACTOR  = 50;
final int LIMITEDVIEW_RADIUS_FACTOR = 30;
 
final int SEPARATION_FACTOR         = 5;
final int BACK_VIEW_ANGLE_FACTOR    = 1;
final int FRONT_VIEW_ANGLE_FACTOR   = 1;
 
final int NUM_OBSTACLES             = 8;
 
final float rho = 0.0023769f;         // 地上の空気密度 slugs/ft^3
final float tol = 0.000000000000001f; // 許容誤差
 
RigidBody2D[] units;
PVector       target;
PVector[]     obstacles;
 
boolean initialize() {
  obstacles = new PVector[NUM_OBSTACLES];
   
  units = new RigidBody2D[MAX_NUM_UNITS];
   
  for(int i = 0; i < MAX_NUM_UNITS; i++) {
    units[i] = new RigidBody2D();
     
    units[i].mass = 10;
    units[i].inertia = 10;
    units[i].inertiaInverse = 1 / 10;
    units[i].position.x = random(width);   //random(width * 0.5 - SPAWN_AREA_R, width * 0.5 + SPAWN_AREA_R);
    units[i].position.y = random(height);  //random(height *0.5 - SPAWN_AREA_R, height * 0.5 - SPAWN_AREA_R);
    units[i].width = UNIT_LENGTH / 2;
    units[i].length = UNIT_LENGTH;
    units[i].height = UNIT_LENGTH;
    units[i].orientation = random(0, TWO_PI);
    units[i].cd.y  = -0.12f * units[i].length; units[i].cd.x  =  0.0f;                   // 回転中心座標
    units[i].ct.y  = -0.50f * units[i].length; units[i].ct.x  =  0.0f;                   // 推進ベクトル
    units[i].cpt.y =  0.5f  * units[i].length; units[i].cpt.x = -0.5f + units[i].width;  // 左舷操舵ベクトル
    units[i].cst.y =  0.5f  * units[i].length; units[i].cst.x =  0.5f + units[i].width;  // 右舷操舵ベクトル
     
    units[i].projectedArea = (units[i].length + units[i].width) * units[i].height;
     
    units[i].leader = false;
     
    if(i > MAX_NUM_UNITS / 2) {
      units[i].interceptor = true;
      units[i].thrustForce = THRUSTFORCE * 1.5f;
    } else {
      units[i].interceptor = false;
      units[i].thrustForce = THRUSTFORCE;
    }
  }
   
  for(int i = 0; i < NUM_OBSTACLES; i++) {
    obstacles[i] = new PVector();
     
    obstacles[i].x = random(OBSTACLE_RADIUS * 4, width  - OBSTACLE_RADIUS * 4);
    obstacles[i].y = random(OBSTACLE_RADIUS * 4, height - OBSTACLE_RADIUS * 4);
  }
  return true; 
}
 
void doUnitAI(int i) {
  PVector pave = new PVector();  // 平均位置ベクトル
  PVector vave = new PVector();  // 平均速度ベクトル
  PVector fs   = new PVector();  // 最終操舵力
  PVector pfs  = new PVector();  // fsの適用位置
  PVector d    = new PVector();
  PVector u    = new PVector();
  PVector v    = new PVector();
  PVector w    = new PVector();
  double  m    = 0;
  int     nf;
  boolean inView;
  boolean doFlock = wideView | limitedView | narrowView;
  int     radiusFactor = 0;
   
  int n = 0;
  pfs.y = units[i].length / 2.0f;
  nf    = 0;
  
  for(int j = 1; j < MAX_NUM_UNITS; j++) {
    if(i != j) {
      inView = false;
      d = PVector.sub(units[j].position, units[i].position);
      w = rotate2D(-units[i].orientation, d);
       
      if(((w.y > 0) && (abs(w.x) < abs(w.y) * FRONT_VIEW_ANGLE_FACTOR)))
        if(d.mag() <= (units[i].length * NARROWVIEW_RADIUS_FACTOR))
          nf++;
       
      if(wideView) {
        inView = ((w.y > 0) || ((w.y < 0) && (abs(w.x) > abs(w.y) * BACK_VIEW_ANGLE_FACTOR)));
        radiusFactor = WIDEVIEW_RADIUS_FACTOR;
      }
       
      if(limitedView) {
        inView = (w.y > 0);
        radiusFactor = LIMITEDVIEW_RADIUS_FACTOR;
      }
       
      if(narrowView) {
        inView = (((w.y > 0) && (abs(w.x) < abs(w.y) * FRONT_VIEW_ANGLE_FACTOR)));
        radiusFactor = NARROWVIEW_RADIUS_FACTOR;
      }
       
      if(inView && (units[i].interceptor == units[j].interceptor)) {
        if(d.mag() <= (units[i].length * radiusFactor)) {
          pave.add(units[j].position);
          vave.add(units[j].velocity);
          n++;
        }
      }
       
      if(inView) {
        if(d.mag() <= (units[i].length * SEPARATION_FACTOR)) {
          if(w.x < 0) m =  1;
          if(w.x > 0) m = -1;
           
          fs.x += m * STEERINGFORCE * (units[i].length * SEPARATION_FACTOR) / d.mag();
        }
      }
    }
  }
   
  // Cohesion Rule:
  if(doFlock && (n > 0)) {
    pave.div(n);
    v.set(units[i].velocity.x, units[i].velocity.y, units[i].velocity.z);
    v.normalize();
    u = PVector.sub(pave, units[i].position);
    u.normalize();
    w = rotate2D(-units[i].orientation, u);
    if(w.x < 0) m = -1;
    if(w.x > 0) m =  1;
    if(abs(v.dot(u)) < 1.0f)
      fs.x += m * STEERINGFORCE * acos(v.dot(u)) / PI;
  }
   
  // Alignment Rule:
  if(doFlock && (n > 0)) {
    vave.div(n);
    u.set(vave.x, vave.y, vave.z);
    u.normalize();
    v.set(units[i].velocity.x, units[i].velocity.y, units[i].velocity.z);
    v.normalize();
    w = rotate2D(-units[i].orientation, u);
    if(w.x < 0) m = -1;
    if(w.x > 0) m =  1;
    if(abs(v.dot(u)) < 1.0f)
      fs.x += m * STEERINGFORCE * acos(v.dot(u)) / PI;
  }
 
  // 追跡 if the unit is a leader
  if(chase) {
    if(nf == 0)
      units[i].leader = true;
    else
      units[i].leader = false;
     
    if((units[i].leader || !doFlock)) {
      if(!units[i].interceptor) {
        // Chase
        u.set(units[0].position.x, units[0].position.y, units[0].position.z);
        d = PVector.sub(u, units[i].position);
        w = rotate2D(-units[i].orientation, d);
        if(w.x < 0) m = -1;
        if(w.x > 0) m =  1;
        fs.x += m * STEERINGFORCE;
      } else {
        // Intercept
        PVector s1, s2, s12;
        float   tClose;
        PVector vr12;
         
        vr12 = PVector.sub(units[0].velocity, units[i].velocity);
        s12  = PVector.sub(units[0].position, units[i].position);
        tClose = s12.mag() / vr12.mag();
         
        s1 = PVector.add(units[0].position, PVector.mult(units[0].velocity, tClose));
        target = s1;
        s2 = PVector.sub(s1, units[i].position);
        w = rotate2D(-units[i].orientation, s2);
        if(w.x < 0) m = -1;
        if(w.x > 0) m =  1;
        fs.x += m * STEERINGFORCE;
      }
    }
  }
   
  // 衝突回避
  PVector a, p, b;
  for(int j = 0; j < NUM_OBSTACLES; j++) {
    u.set(units[i].velocity.x, units[i].velocity.y, units[i].velocity.z);
    u.normalize();
    v = PVector.mult(u, COLLISION_VISIBILITY_FACTOR * units[i].length);
     
    a = PVector.sub(obstacles[j], units[i].position);
    p = PVector.mult(u, a.dot(u));
    b = PVector.sub(p, a);
     
    if((b.mag() < OBSTACLE_RADIUS) && (p.mag() < v.mag())) {
      w = rotate2D(-units[i].orientation, a);
      w.normalize();
      if(w.x < 0) m =  1;
      if(w.x > 0) m = -1;
      fs.x += m * STEERINGFORCE * (COLLISION_VISIBILITY_FACTOR * units[i].length) / a.mag();
    }
  }
   
  units[i].fa = fs;
  units[i].pa = pfs;
}
 
void updateSimulation() {
  float dt = TIMESTEP;
   
  units[0].setThrusters(false, false, 1);
 
  if(keyPressed && key == CODED) {
    if(keyCode == RIGHT)
      units[0].setThrusters(true, false, 0.5f);
    if(keyCode == LEFT)
      units[0].setThrusters(false, true, 0.5f);
  }
   
  for(int c = 0; c < 60; c++) {
    units[0].updateBodyEuler(dt);
     
    if(units[0].position.x > width)  units[0].position.x = 0;
    if(units[0].position.x < 0)      units[0].position.x = width;
    if(units[0].position.y > height) units[0].position.y = 0;
    if(units[0].position.y < 0)      units[0].position.y = height;
     
    for(int i = 1; i < MAX_NUM_UNITS; i++) {
      doUnitAI(i);
      units[i].updateBodyEuler(dt);
   
      if(units[i].position.x > width)  units[i].position.x = 0;
      if(units[i].position.x < 0)      units[i].position.x = width;
      if(units[i].position.y > height) units[i].position.y = 0;
      if(units[i].position.y < 0)      units[i].position.y = height;   
    }
  }
   
  randomSeed(0);
  for(int i = 0; i < MAX_NUM_UNITS; ++i) {
    drawCraft(units[i], 0xFFFF0000);
  }
   
  // drawObstacles();
}
 
void drawCraft(RigidBody2D craft, int clr) {
  PVector[] vList = new PVector[4];
   
  float wd = craft.width;
  float lg = craft.length;
  vList[0] = new PVector( wd / 2,  lg / 2);
  vList[1] = new PVector( wd / 2, -lg / 2);
  vList[2] = new PVector(-wd / 2, -lg / 2);
  vList[3] = new PVector(-wd / 2,  lg / 2);
  /*
  vList[4] = new PVector(      0,  lg / 2 * 1.5f);
   */
  for(int i = 0; i < vList.length; i++) {
    PVector v1 = rotate2D(craft.orientation, vList[i]);
    vList[i] = PVector.add(v1, craft.position);
  }
   
   /*
  stroke(clr);
  stroke(255);
  strokeWeight(2);
  line(vList[0].x, vList[0].y, 0, vList[1].x, vList[1].y, 0);
  line(vList[1].x, vList[1].y, 0, vList[2].x, vList[2].y, 0);
  line(vList[2].x, vList[2].y, 0, vList[3].x, vList[3].y, 0);
  line(vList[3].x, vList[3].y, 0, vList[0].x, vList[0].y, 0);
  //line(vList[4].x, vList[4].y, 0, vList[0].x, vList[0].y, 0);
   */
  pushMatrix();

  translate( craft.position.x,  craft.position.y, 0);
  rotateZ(random(0, TWO_PI) * frameCount * 0.03);
  rotateY(random(0, TWO_PI) * frameCount * 0.03);
  rotateX(random(0, TWO_PI) * frameCount * 0.03);
  translate(-craft.position.x, -craft.position.y, 0);
  
  beginShape();
  texture(img);
  vertex(vList[0].x, vList[0].y, 0, 0, 0);
  vertex(vList[1].x, vList[1].y, 0, 0, img.height);
  vertex(vList[2].x, vList[2].y, 0, img.width, img.height);
  vertex(vList[3].x, vList[3].y, 0, img.width, 0);
  endShape();
  
  popMatrix();
}
 
void drawObstacles() {
  /*
  stroke(255);
  for(int i = 0; i < NUM_OBSTACLES; i++) {
    ellipse(obstacles[i].x, obstacles[i].y, OBSTACLE_RADIUS, OBSTACLE_RADIUS);
  }*/
}
boolean wideView    = false;  // 視野: 広い
boolean limitedView = false;  //     : そこそこ
boolean narrowView  = false;  //     : 狭い
 
boolean chase       = false;  // 追跡モード
class Boid implements State {
  private int _counter;
  Boid() {
    _counter = 0;
    
    initialize();
    wideView = true;
  }
  
  State update() {
    updateSimulation();
    
    if(++_counter < 220) return this;
    
    return new LogoDisplay();
  }
}
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
  protected State  nextState;
  protected Transition() {}
  
  Transition(PImage img1, PImage img2, int dir, State nextState) {    
    prev      = img1;
    next      = img2;
    direction = dir;
    counter   = 0;
    this.nextState = nextState;
  }

}

int g_Direction;
class Mosaic extends Transition implements State {
  final float SPEED = 0.05;
  Mosaic(PImage img1, PImage img2, int direction, State nextState) {
    super(img1, img2, direction, nextState);
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

    return ++counter < 40 ? this : nextState;
  }
}

class Mosaic2 extends Transition implements State {
  final float SPEED = 0.5;
  final float ROTATE_SPEED = 0.025;
  long zoomCounter;
  Mosaic2(PImage img1, PImage img2, int direction, State nextState) {
    super(img1, img2, direction, nextState);
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

    
    return angle < HALF_PI ? this : nextState;
    
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
class LogoDisplay implements State {
  private final int N = 15;
  private final int[] timers;

  private float  cameraAngle;

  private int _counter;
  private PImage blackImg;
  public LogoDisplay() {
    _counter = 0;
    
    // ----------------------------------------
    // タイマー用の変数を初期化
    timers = new int[N * N];    
    for(int i = 0; i < N; ++i) {
      for(int j = 0; j < N; ++j) {
        timers[i * N + j] = 100 + i + j;
      }
    }
    cameraAngle = 100;
    
    blackImg = loadImage("black.png");
  }
  
  State update() {
    
    if(blackImg.get(0,0) == 0) return this;
    
    final float FRAGMENT_WIDTH  = (float)width  / N;
    final float FRAGMENT_HEIGHT = (float)height / N;
    
    final float MAX_SPEED = 20;
    final float MAX_ANGULAR_RATE = 10;
    
    background((20 * _counter) < 0xFF ? 0xFF - (20 * _counter) : 0);
    ++_counter;

    
    fill(255);
    camera();
    
    randomSeed(0);
    cameraAngle = 0 < cameraAngle ? cameraAngle - 1 : 0;

    final float MAX_CAMERA_ANGULAR_RATE = 1.5;
    // ------------------------------------------------------------
    // カメラの回転操作
    translate( 0.5 * width,  0.5 * height, 0);                                                 // ⑤ ①の並進移動をリセット
    rotateZ(radians(random(-MAX_CAMERA_ANGULAR_RATE, MAX_CAMERA_ANGULAR_RATE) * cameraAngle)); // ④ y軸まわりに回転
    rotateY(radians(random(-MAX_CAMERA_ANGULAR_RATE, MAX_CAMERA_ANGULAR_RATE) * cameraAngle)); // ③ y軸まわりに回転
    rotateX(radians(random(-MAX_CAMERA_ANGULAR_RATE, MAX_CAMERA_ANGULAR_RATE) * cameraAngle)); // ② x軸まわりに回転
    translate(-0.5 * width, -0.5 * height, 0);                                                 // ① 投影面中心を原点(0, 0, 0)に合わせる
    // ------------------------------------------------------------
    
    for(int i = 0; i < N ; ++i) {
      for(int j = 0; j < N ; ++j) {
        pushMatrix();

        int coef = max(0, --timers[i * N + j]);

        translate((i + 0.5) * FRAGMENT_WIDTH, 
                  (j + 0.5) * FRAGMENT_HEIGHT, 
                  0);
        
        translate(random(-MAX_SPEED, MAX_SPEED) * coef,
                  random(-MAX_SPEED, MAX_SPEED) * coef,
                  random(-MAX_SPEED, MAX_SPEED) * coef);
        
        rotateX(radians(random(-MAX_ANGULAR_RATE, MAX_ANGULAR_RATE) * coef));
        rotateY(radians(random(-MAX_ANGULAR_RATE, MAX_ANGULAR_RATE) * coef));
        rotateZ(radians(random(-MAX_ANGULAR_RATE, MAX_ANGULAR_RATE) * coef));

        beginShape();
        texture(img);
        
        vertex(-0.5 * FRAGMENT_WIDTH, -0.5 * FRAGMENT_HEIGHT, 0,    i  * FRAGMENT_WIDTH,    j  * FRAGMENT_HEIGHT);
        vertex(-0.5 * FRAGMENT_WIDTH,  0.5 * FRAGMENT_HEIGHT, 0,    i  * FRAGMENT_WIDTH, (j+1) * FRAGMENT_HEIGHT);
        vertex( 0.5 * FRAGMENT_WIDTH,  0.5 * FRAGMENT_HEIGHT, 0, (i+1) * FRAGMENT_WIDTH, (j+1) * FRAGMENT_HEIGHT);
        vertex( 0.5 * FRAGMENT_WIDTH, -0.5 * FRAGMENT_HEIGHT, 0, (i+1) * FRAGMENT_WIDTH,    j  * FRAGMENT_HEIGHT);

        endShape(CLOSE);
        
        popMatrix();
      }
    }

    if (_counter < 100 + 2 * N) return this;
    
    return new Mosaic2(img, blackImg, 2, new SensuEffect());
  }
}


class OrigamiEffect implements State {
  Origami origami;
  
  private final int MAX_FOLDS = 3;  // 最大折りたたみ回数
  private int _numFolds;            // 折りたたんだ回数
  
  int _counter;
  int _zOffset;
  
  PImage _img;
  PImage _bg;
  
  OrigamiEffect() {
    noStroke();  
    _img = loadImage("yagasuri.png");
    _bg  = loadImage("arrowpattern.png");
    origami = new Origami(100, 150, 0, _img);
    _numFolds = 0;
    _zOffset = 0;
  }

  State update() {
    background(0);
    if(_img.get(0, 0) == 0 || _bg.get(0, 0) == null) return this;
    
    float angle = 0.5 * radians(++_counter);
    
    camera();
    
    pushMatrix();
  
    drawBackground(_bg);
  
    translate(width/2, height/2, _numFolds < MAX_FOLDS-1 ? 0 : -pow(++_zOffset, 2));
    rotateZ(PI);
    rotateX(HALF_PI - angle);

    rotateY(angle);
    
    // 折りたたむアニメーションを行いつつ
    // ちゃっかり折りたたんだ回数も数える
    Origami tmp = origami.update();
    if(origami != tmp && ++_numFolds == 1) {
      lines.clear();
      lines.add("Origami Effect");
    }
    
    origami = tmp;
    popMatrix();

    return _numFolds < MAX_FOLDS ? this : new SensuEffect();
  }
}

// テクスチャ座標を保持するクラス
class TextureCoords {
  final int NUM_COORDS = 4;
  public PVector[] uvCoords;
  TextureCoords() {
    uvCoords = new PVector[NUM_COORDS];
    for(int i = 0; i < NUM_COORDS; ++i) {
      uvCoords[i] = new PVector();
    }
  }
}

class Origami {
  private float _width;
  private float _height;
  
  private float _angle;
  private int   _count;
  private int   _direction;
  
  private PImage _img; 
  
  private TextureCoords _entireTexCoords;
  private TextureCoords _innerTexCoords1;
  private TextureCoords _innerTexCoords2;
  private TextureCoords _outerTexCoords;
  
  Origami(float w, float h, int dir, PImage img) {
    _img = img;
    
    // サイズを設定
    _width  = w;
    _height = h;
    
    // 紙を開く方向を設定
    _direction = dir;
    
    // カウンタを0クリア
    _count  = 0;
    
    // テクスチャ座標保持オブジェクト
    _entireTexCoords = new TextureCoords();
    _innerTexCoords1 = new TextureCoords();
    _innerTexCoords2 = new TextureCoords();
    _outerTexCoords  = new TextureCoords(); 
  }
  
  // テクスチャ座標保持オブジェクトをセットアップ
  private void initEntireTexCoords() {
    _entireTexCoords.uvCoords[0] = new PVector(0, 0);
    _entireTexCoords.uvCoords[1] = new PVector(0, _img.height);
    _entireTexCoords.uvCoords[2] = new PVector(_img.width, _img.height);
    _entireTexCoords.uvCoords[3] = new PVector(_img.width, 0);
  }
  
  // 更新
  Origami update() {
    if(_count == 0) initEntireTexCoords();
    
    // 紙をめくる角度
    _angle = radians(_count);
    
    // 符号
    int sign = _direction < 2 ? -1 : 1;    
    
    pushMatrix();
        
    // 注視点が常に重心を追尾するよう再計算を行い並進移動する。
    float offsetX = _direction % 2 == 0 ? sign * (1.0 -_count / 180.0f) * _width : 0;
    float offsetZ = _direction % 2 == 0 ? 0 : sign * (1.0 -_count / 180.0f) * _height;
    translate(offsetX, 0, offsetZ);
    
    // 内側のテクスチャ座標を計算
    getInnerTextureCoords(_direction,
      _entireTexCoords,
      _innerTexCoords1,
      _innerTexCoords2);

    // 外側のテクスチャ座標を計算
    getOuterTextureCoords(_direction,
      _entireTexCoords,
      _outerTexCoords);
    
    // 折り重なる紙を描く。
    for(int i : new int[]{0, 1}) {
      pushMatrix();
      
      // うち1枚目だけは、紙を折り開くアニメーションのために並進 + 回転運動を適用する。
      if(i % 2 == 0) {
        offsetX = _direction % 2 == 0 ? sign * _width : 0;
        offsetZ = _direction % 2 == 0 ? 0 : sign * _height;
        _angle = sign * radians(180- _count);
      } else {
        offsetX = 0;
        offsetZ = 0;
        _angle = PI;
      }
      
      // 紙をパタンと閉じるアニメーション
      translate(-offsetX, 0, -offsetZ);
      if (_direction % 2 == 0) 
        rotateZ(_angle);
      else {
        rotateX(-_angle);
      }
      translate(offsetX, 0, offsetZ);
      
      // どの方向から開いても、テクスチャの上下左右の方向が揃うよう
      // Y軸まわりの回転補正。
      rotateY(_direction % 2 == 0 ? 0 : PI );
      
      // テクスチャを内と外で描き分ける
      for(int j : new int[] {0, 1}) {
        beginShape();
        texture(_img);
        TextureCoords _coords = j > 0 ? _outerTexCoords : i % 2 == 0 ? _innerTexCoords1 : _innerTexCoords2;
        vertex(-_width, 0.2 * j, -_height, _coords.uvCoords[0].x, _coords.uvCoords[0].y);
        vertex(-_width, 0.2 * j,  _height, _coords.uvCoords[1].x, _coords.uvCoords[1].y);
        vertex( _width, 0.2 * j,  _height, _coords.uvCoords[2].x, _coords.uvCoords[2].y);
        vertex( _width, 0.2 * j, -_height, _coords.uvCoords[3].x, _coords.uvCoords[3].y);
        endShape(CLOSE);
      }
      
      popMatrix();
    }
    popMatrix();

    // 遷移制御。
    _count += 10;
    if(_count < 180) return this;
    
    // 次の状態へ遷移する。
    float newWidth  = _direction % 2 == 0 ? _width : _width * 0.5;
    float newHeight = _direction % 2 == 0 ? _height * 0.5: _height;
    
    return new Origami(newWidth, newHeight, ++_direction % 4, _img);
  }
  
  // テクスチャのUV座標を求める
  void getOuterTextureCoords(int direction,
    TextureCoords entireCoords,
    TextureCoords outerCoords) {
      
      if(direction % 2 == 0) {
        outerCoords.uvCoords[0].set(entireCoords.uvCoords[3]);
        outerCoords.uvCoords[1].set(entireCoords.uvCoords[2]);
        outerCoords.uvCoords[2].set(entireCoords.uvCoords[1]);
        outerCoords.uvCoords[3].set(entireCoords.uvCoords[0]);
        
      } else {
        outerCoords.uvCoords[0].set(entireCoords.uvCoords[1]);
        outerCoords.uvCoords[1].set(entireCoords.uvCoords[0]);
        outerCoords.uvCoords[2].set(entireCoords.uvCoords[3]);
        outerCoords.uvCoords[3].set(entireCoords.uvCoords[2]);
      }
  }
  
  // テクスチャのUV座標を求める
  // ここソースがカオスすぎる…。
  void getInnerTextureCoords(int direction,
    TextureCoords entireCoords,
    TextureCoords innerCoords1,
    TextureCoords innerCoords2) {
      
      if(direction == 0) {
        innerCoords1.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords1.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords1.uvCoords[2].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[2].y);
        innerCoords1.uvCoords[3].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[3].y);
        
        innerCoords2.uvCoords[0].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[0].y);
        innerCoords2.uvCoords[1].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[1].y);
        innerCoords2.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords2.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
      } else if(direction == 1) {
        innerCoords1.uvCoords[0].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords1.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords1.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords1.uvCoords[3].set(entireCoords.uvCoords[3].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
        
        innerCoords2.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords2.uvCoords[1].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords2.uvCoords[2].set(entireCoords.uvCoords[2].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
        innerCoords2.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
      } else if(direction == 2) {
        innerCoords2.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords2.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords2.uvCoords[2].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[2].y);
        innerCoords2.uvCoords[3].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[3].y);
        
        innerCoords1.uvCoords[0].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[0].y);
        innerCoords1.uvCoords[1].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[1].y);
        innerCoords1.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords1.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
      } else {
        innerCoords1.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords1.uvCoords[1].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords1.uvCoords[2].set(entireCoords.uvCoords[2].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
        innerCoords1.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
        innerCoords2.uvCoords[0].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords2.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords2.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords2.uvCoords[3].set(entireCoords.uvCoords[3].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
      }
  }
}
/* Flocking */

final float THRUSTFORCE            = 3000.0f;
final float MAXTHRUST              = 4000.0f;
final float MINTHRUST              = 0.0f;
final float DTHRUST                = 10.0f;
final float STEERINGFORCE          = 500.f;
final float LINEARDRAGCOEFFICIENT  = 10.5f;
final float ANGULARDRAGCOEFFICIENT = 2000.0f;
 
class RigidBody2D {
  float mass;
  float inertia;
  float inertiaInverse;
   
  PVector position;         // 世界座標空間の位置
  PVector velocity;         // 　　　〃　　　速度
  PVector velocityBody;     // ローカル座標空間の速度
  PVector angularVelocity;  // 　　　　〃　　　　角速度
   
  float speed;              // 速さ（速度の大きさ）
  float orientation;        // オリエンテーション
   
  PVector forces;           // 力
  PVector moment;           // モーメント（Z軸まわりのみ）
   
  float thrustForce;        // 推力の大きさ
  PVector pThrust, sThrust; // 操舵力
   
  float width;
  float length;
  float height;
   
  PVector cd;
  PVector ct;
  PVector cpt;
  PVector cst;
   
  float projectedArea;
  PVector fa;
  PVector pa;
   
  boolean leader;
  boolean interceptor;
   
  RigidBody2D() {
    position        = new PVector();
    velocity        = new PVector();
    velocityBody    = new PVector();
    angularVelocity = new PVector();
     
    forces          = new PVector();
    moment          = new PVector();
     
    pThrust         = new PVector();
    sThrust         = new PVector();
     
    cd              = new PVector();
    ct              = new PVector();
    cpt             = new PVector();
    cst             = new PVector();
   
    fa              = new PVector();
    pa              = new PVector();
  }
   
  void calcLoads() {
    forces.set(0, 0, 0);
    moment.set(0, 0, 0);
     
    PVector fb     = new PVector();                  // 力の合計
    PVector mb     = new PVector();                  // モーメントの合計
    PVector thrust = new PVector(0.0f, 1.0f, 0.0f);  // 推進ベクトル
     
    thrust.mult(thrustForce);
     
    PVector localVelocity = new PVector();
    float   localSpeed;
    PVector dragVector = new PVector();
    float   tmp;
    PVector resultant = new PVector();
    PVector vtmp;
     
    vtmp = angularVelocity.cross(cd);
    localVelocity = PVector.add(velocityBody, vtmp);
     
    localSpeed = localVelocity.mag();
     
    if(localSpeed > tol) {
      localVelocity.normalize();
      dragVector.set(-localVelocity.x, -localVelocity.y, -localVelocity.z);
       
      float f;
      if(thrust.dot(localVelocity) / (thrust.mag() * localVelocity.mag()) > 0)
        f = 2;
      else
        f = 1;
         
      tmp = 0.5f * rho * localSpeed * localSpeed * projectedArea * f;
      resultant = PVector.mult(dragVector, LINEARDRAGCOEFFICIENT * tmp);
       
      fb.add(resultant);
       
      vtmp = cd.cross(resultant);
      mb.add(vtmp);
    }
     
    fb.add(PVector.mult(pThrust, 3));
     
    vtmp = cpt.cross(pThrust);
    mb.add(vtmp);
     
    fb.add(PVector.mult(sThrust, 3));
     
    vtmp = cst.cross(sThrust);
    mb.add(vtmp);
     
    fb.add(fa);
    vtmp = pa.cross(fa);
    mb.add(vtmp);
     
    if(angularVelocity.mag() > tol) {
      vtmp.x = 0;
      vtmp.y = 0;
      tmp = 0.5f * rho * angularVelocity.z * angularVelocity.z * projectedArea;
      if(angularVelocity.z > 0.0)
        vtmp.z = -ANGULARDRAGCOEFFICIENT * tmp;
      else
        vtmp.z = ANGULARDRAGCOEFFICIENT * tmp;
      mb.add(vtmp);
    }
     
    fb.add(thrust);
    forces = rotate2D(orientation, fb);
    moment.add(mb);
  }
   
  void updateBodyEuler(float dt) {
    // 力とモーメントの計算
    calcLoads();
     
    PVector a = PVector.div(forces, mass);
     
    PVector dv = PVector.mult(a, dt);
    velocity.add(dv);
     
    PVector ds = PVector.mult(velocity, dt);
    position.add(ds);
     
    float aa  = moment.z / inertia;
    float dav = aa * dt;
    angularVelocity.z += dav;
     
    float dr = angularVelocity.z * dt;
    orientation += dr;
     
    speed = velocity.mag();
    velocityBody = rotate2D(-orientation, velocity);
  }
   
  void setThrusters(boolean p, boolean s, float f) {
    pThrust.x = 0;
    pThrust.y = 0;
    sThrust.x = 0;
    sThrust.y = 0;
     
    if(p) pThrust.x = -STEERINGFORCE * f;
    if(s) sThrust.x =  STEERINGFORCE * f;
  }
   
  void modulateThrust(boolean up) {
    float dT = up ? DTHRUST : -DTHRUST;
    thrustForce += dT;
     
    if(thrustForce > MAXTHRUST) thrustForce = MAXTHRUST;
    if(thrustForce < MINTHRUST) thrustForce = MINTHRUST;
  }
}
 
PVector rotate2D(float angle, PVector u) {
  float x, y;
  x =  u.x * cos(-angle) + u.y * sin(-angle);
  y = -u.x * sin(-angle) + u.y * cos(-angle);
  return new PVector(x, y);
}
float FAR_CLIP = 1000;
float PATTERN_SIZE = 101;

// 描画が終わったパターンの数をかぞえるよ
int seigaihaPatternCounter;

class Seigaiha {
  ArrayList<Row> rows;
  private long counter;
  // private boolean finished;
  Seigaiha() {
    rows = new ArrayList<Row>();
    counter = 0;
    seigaihaPatternCounter = 0;
  }
  
  long getNumPatterns() {
    return (long)(height / (0.25 * PATTERN_SIZE) + 1) * rows.get(0).getNumPatterns();
  }
  
  boolean finished() {
    return seigaihaPatternCounter > getNumPatterns();
  }
  
  Seigaiha update() {
    camera();
    
    // カメラ焦点距離
    final float FOCAL_LENGTH = height * 0.5 / tan(PI / 6.0);
  
    translate( 0.5 * width,  0.5 * height, -FAR_CLIP);
    scale((FOCAL_LENGTH + abs(FAR_CLIP)) / FOCAL_LENGTH);
    translate(-0.5 * width, -0.5 * height, 0);
    
    if(rows.size() == 0) {
      rows.add(new Row(height + 0.25 * PATTERN_SIZE));
    }
    
    if((++counter % (int)(3.5 * rows.get(0).getNumPatterns())) == 0) {
      if(rows.size() < height / (0.25 * PATTERN_SIZE) + 1) {
        rows.add(new Row(height + (1 - rows.size()) * 0.25 * PATTERN_SIZE));
      } 
    }
    
    for(int i = rows.size()-1; !(i < 0); --i) {
      pushMatrix();
      if(i % 2 != 0) {
        translate(0.5 * PATTERN_SIZE, 0);
      }
      translate(0, 0, -i);
      rows.set(i, rows.get(i).update());
      
      popMatrix();
    }
    
    noStroke();
    return this;
  }
}

class Row {
  ArrayList<Pattern> patterns;
  private long counter;
  private float y;
  Row(float y) {
    patterns = new ArrayList<Pattern>();
    counter  = 0;
    this.y   = y;
  }
  
  long getNumPatterns() {
    return (long)(width / PATTERN_SIZE + 1);
  }
  
  Row update() {
    if(counter++ % 4 == 0) {
      if (patterns.size() < getNumPatterns()) {
        patterns.add(new Pattern(patterns.size() * PATTERN_SIZE, y));
      }
    }
    for(int i = 0; i < patterns.size(); ++i) {
      patterns.set(i, patterns.get(i).update());
    }
    return this;
  }
}

class Pattern {
  private long counter;
  private float x, y;
  private final float SPEED = 10.0;
  private boolean finished;
  
  Pattern(float x, float y) {
    this.x = x;
    this.y = y;
    finished = false;
  }
  
  float getSize() {
    return PATTERN_SIZE;
  }
  
  Pattern update() {
    float angle = min(SPEED * radians(counter), PI);

    noFill();
    fill(0);
    stroke(0xFF00CCFF);
    for(float r = PATTERN_SIZE; !(r < 0); r -= 15) {
      if(angle < PI) {
        arc(x, y, r, r, PI, PI+angle);
      } else {
        if(!finished) {
          ++seigaihaPatternCounter;
          finished = true;
        }
        ellipse(x, y, r, r);
      }
      noFill();
    }
    noStroke();
    
    ++counter;
    return this;
  }
}
class SensuEffect implements State {
  private State[] sensuArray;
  private int counter;
  private Seigaiha seigaiha;
  private PImage backgroundImg;
  private PImage yagasuriImg;
  SensuEffect() {
    sensuArray = new Sensu[4];
    counter = 0;
    this.seigaiha = seigaiha;
    
    seigaiha = new Seigaiha();    
    backgroundImg = loadImage("seigaiha.png");
    yagasuriImg   = loadImage("yagasuri.png");
  }
    
  State update() {   
    if(backgroundImg.get(0, 0) == 0) return;
    
    pushMatrix();
    translate(0, 0, (20 * counter) < 0xFF ? 0xFF - (20 * counter) : 0);
    
    pushMatrix();
    if(counter++ % 100 == 0) {
      int index = (int)(counter / 100);
      // ちょっと扇子が無限に湧き出るのはアレなので、2こまでにする
      if(index < 2) {
        int rSeed = index % 2 == 0 ? (int)(random(100)) * 2 : (int)(random(100)) * 2 + 1;
        sensuArray[index] = new Sensu(rSeed);
      }
    }
    
    for(int i = 0; i < sensuArray.length; ++i) {
      if(sensuArray[i] == null) continue;
      sensuArray[i] = sensuArray[i].update();
    }
    popMatrix();
    popMatrix();
    
    seigaiha = seigaiha.update();
    
    return seigaiha.finished() ? new Mosaic(backgroundImg, yagasuriImg, 3, new OrigamiEffect()) : this;
  }
}

class Sensu implements State {
  final  float LEN = 230;
  final  float LEN2 = 80;
  final  float MAX_ANGLE = radians(120);
  final  int   NUM_BONE = 19; 
  final  float THICKNESS = 1;
  final  float BONE_WIDTH = 3;
  
  PImage textureImage;
  int counter, subCounter;
  int rSeed;
  Sensu(int seed) {
    textureImage = loadImage("hau.png");
    counter = 0;
    subCounter = 0;
    
    rSeed = seed;
    noStroke();
  }
  
  State update() {

    randomSeed(rSeed);
    if(textureImage.get(0,0) == 0) return this;
    
    pushMatrix();
    noFill();
    translate(rSeed % 2 == 0 ? -0.25 * width : 0.25 * width, ++counter * 3, 0);    
    translate(0, 0, -100);
    
    translate(0.5 * width, 0.5*LEN, 0);
    rotateZ(random(-1.0, 1.0) * radians(counter));
    rotateY(random(-1.0, 1.0) * radians(counter));
    rotateX(random(-1.0, 1.0) * radians(counter));
    translate(-0.5 * width, -0.5*LEN, 0);
    
    translate(0.5 * width, 0, 0);

    pushMatrix();
  
    for(int i = 0; i < NUM_BONE; ++i) {
      
      float z = THICKNESS * (i - 0.5 * NUM_BONE);
      
      float angle = min(0.8 * radians(subCounter++), MAX_ANGLE) * ((float)i / NUM_BONE - 0.5);    
  
      pushMatrix();
      translate(0,  LEN);
      rotateZ(angle);
      translate(0, -LEN);
  
      stroke(0);
      noStroke();
      beginShape(QUAD_STRIP);
      texture(textureImage);
      for(float coef : new float[] {0 , 1 }) {
  
        float theta = (coef - 0.5) * MAX_ANGLE / NUM_BONE;
        float textureAngle = MAX_ANGLE * ((i + coef) / NUM_BONE - 0.5);
  
        float x, y, u, v;
        x = LEN2 * sin(theta);
        y = LEN - LEN2 * cos(theta);
        u = 0.5 * textureImage.width * (1 + LEN2 * sin(textureAngle) / (LEN * sin(0.5 * MAX_ANGLE)));
        v = (LEN - LEN2 * cos(textureAngle)) * (float)textureImage.height / LEN;
        vertex(x, y, z, u, v);
  
        x = LEN * sin(theta);
        y = LEN * (1 - cos(theta));
        
        u = 0.5 * textureImage.width * (1 + sin(textureAngle) / sin(0.5 * MAX_ANGLE));
        v = (1 - cos(textureAngle)) * (float)textureImage.height;
        vertex(x, y, z, u, v);
      }
      
      endShape();  
      popMatrix();
      
      lights();
      fill(100, 80, 0);
      // Bone
      pushMatrix();
      translate(0, LEN, z);
      rotateZ(angle);
      translate(0, -0.5 * LEN2, 0);
      box(BONE_WIDTH, LEN2, THICKNESS);
      popMatrix();
      fill(255);
      noLights();
  
    }
    popMatrix(); 
    
    popMatrix();
    return this;
  }
}
interface State {
  State update();
}
ArrayList<String> lines = new ArrayList<String>();
abstract class TypeWriter {
  
  final int MAX_LINES =  5;
  final int FONT_SIZE = 12;
  final int WAIT_TIME = 12;
  final int START_X = 3;
  final int START_Y = 3 + FONT_SIZE;
  final color FONT_COLOR = 0xFFFFFFFF;
  
  final color CARET_INACTIVE_COLOR = 0xFFFFFFFF;
  final color CARET_ACTIVE_COLOR   = 0xFF7F7F7F;
  
  final int CARET_INTERVAL = 5;
  
  int _endPosition;
  
  TypeWriter() {
    _endPosition = 0;
  }
  
  public void addLine(String newLine) {
    addLines(newLine.split("¥n"));
  }
  
  public void addLines(String[] newLines) {
    for(String line : newLines) lines.add(line);
  }
  
  protected int getAllStringLength() {
    int len = 0;
    for(String line : lines) len += line.length();
    return len;
  }
  
  // テンプレートメソッド的な
  TypeWriter update() {
    pushMatrix();

    camera();
    textSize(FONT_SIZE);
    fill(FONT_COLOR);
    
    
    // サブクラスの具象メソッドに委譲
    TypeWriter ret = display();
    
    popMatrix();
    return ret;
  }
  
  // 抽象メソッド
  protected abstract TypeWriter display();
  
  // キャレットを描画
  protected void drawCaret(float x, float y) {
    int caretColor = CARET_INTERVAL - (frameCount % (2 * CARET_INTERVAL)) < 0 ?
      CARET_ACTIVE_COLOR : CARET_INACTIVE_COLOR;
      
    fill(caretColor);
    noStroke();
    text("■", x, y);
    fill(FONT_COLOR);
  }
  
  protected PVector getCaretPos() {
    int textLength = _endPosition;
    for(int i = 0; i < lines.size(); ++i) {
      String str = lines.get(i);
      if(textLength == 0) {
        return new PVector(START_X, 
                          (str.length() == 0 ? (i + 1) : i) * FONT_SIZE + START_Y);
      }
      if(textLength < str.length()) {
        return new PVector(START_X + textWidth(str.substring(0, textLength+1)),
                           START_Y + i * FONT_SIZE);
      }
      textLength -= str.length();
    }
    
    return new PVector(-999, -999);
  }
}

// 文字を打ち出す人
class Typer extends TypeWriter {
  Typer() { this(0); }
  
  Typer(int endPosition) {
    _endPosition = endPosition;
  }
  
  protected TypeWriter display() {
    if(getAllStringLength() == 0) {
      _endPosition = 0;
      return this;
    }
    
    PVector caretPos = getCaretPos();
    drawCaret(caretPos.x, caretPos.y);
    
    int textLength = ++_endPosition;    
    for(int i = 0; i < min(MAX_LINES, lines.size()); ++i) {
      String line = (textLength < lines.get(i).length()) ? 
        lines.get(i).substring(0, textLength) : lines.get(i);
      
      text(line, START_X, START_Y + i * FONT_SIZE);
      textLength -= line.length();
      if(!(0 < textLength)) {
        return this;
      }
    }

    return new Waiter(_endPosition -1);
  }
}

// 待つ人
class Waiter extends TypeWriter {
  int _counter;
  Waiter(int endPosition) {
    _counter = 0;
    _endPosition = endPosition;
  }
  
  protected TypeWriter display() {
    ++_counter;
    for(int i = 0; i < min(MAX_LINES, lines.size()); ++i) {
      String line = lines.get(i);
      text(line, START_X, START_Y + i * FONT_SIZE);
    }
    
    PVector caretPos = getCaretPos();
    drawCaret(caretPos.x, caretPos.y);
    
    return WAIT_TIME < _counter || _endPosition < getAllStringLength() ?
      new Elevator(_endPosition) : this;
  }
}

// 位置を送る人
class Elevator extends TypeWriter {
  int _counter;
  Elevator(int endPosition) {
    _endPosition = endPosition;
    _counter = 0;
  }
  
  protected TypeWriter display() {
    int textLength = ++_endPosition - lines.get(0).length();
    
      PVector caretPos = getCaretPos();
      drawCaret(caretPos.x, caretPos.y);
    
    // 1行目がなめらかに消えるように、
    // 縦方向に縮小するアニメーションを行う。
    if(++_counter < FONT_SIZE) {
      float scaleFactor = 1.0 - _counter / (float)FONT_SIZE;
      pushMatrix();
      translate(0,  FONT_SIZE * 0.5);
      scale(1.0, scaleFactor, 1.0);
      translate(0, - FONT_SIZE * 0.5);
      text(lines.get(0), START_X, START_Y);    
      popMatrix();
    }
    
    // 2行目以降の表示
    for(int i = 1; i < min(MAX_LINES, lines.size()); ++i) {
      String line = lines.get(i);
      textLength -= line.length();
      text(line, START_X, START_Y + i * FONT_SIZE - _counter);
    }
    
    if (0 < textLength && MAX_LINES < lines.size()) {
      String line = textLength < lines.get(MAX_LINES).length() ?
        lines.get(MAX_LINES).substring(0, textLength) : lines.get(MAX_LINES);      
      text(line, START_X, START_Y + (MAX_LINES) * FONT_SIZE - _counter);
    } else  --_endPosition;

    if(_counter < FONT_SIZE) {
      return this;
    }
    _endPosition -= lines.get(0).length();    
    if(MAX_LINES < lines.size() && 
       lines.get(MAX_LINES).length() < textLength)
         _endPosition -= (textLength - lines.get(MAX_LINES).length());

    lines.remove(0);
    return new Typer(_endPosition);
  }
  
  // オーバーライド
  protected PVector getCaretPos() {
    int textLength = _endPosition;
    int i;
    String line = "";
    for(i = 1; i < min(MAX_LINES, lines.size()); ++i) {
      line = lines.get(i);
      textLength -= line.length();
    }
    
    if (0 < textLength && MAX_LINES < lines.size()) {
      line = _counter < lines.get(MAX_LINES).length() ?
        lines.get(MAX_LINES).substring(0, _counter +1) : lines.get(MAX_LINES); 
        
      return line.equals(lines.get(MAX_LINES)) ?
        new PVector(START_X, 
                    START_Y + (MAX_LINES + 1) * FONT_SIZE - _counter) :
        new PVector(START_X + textWidth(line), 
                    START_Y + MAX_LINES * FONT_SIZE - _counter);
    }
    
    return new PVector(START_X, 
                       START_Y + (i + 1) * FONT_SIZE - _counter);
  }
}

void setupTypeWriter() {
  typeWriter.addLine("Processing Advent Calendar 2014");
  typeWriter.addLine("");
  typeWriter.addLine("Dec 15th 2014");
  typeWriter.addLine("");
  typeWriter.addLine("Presented by Tercel");
  typeWriter.addLine("");
  typeWriter.addLine("");
  typeWriter.addLine("void setup() {");
  typeWriter.addLine("  size(400, 300, P3D);");
  typeWriter.addLine("  typeWriter = new Typer();");
  typeWriter.addLine("  frameRate(20);");
  typeWriter.addLine("  setupTypeWriter();");
  typeWriter.addLine("}");

  /*
  typeWriter.addLine("");
  typeWriter.addLine("void draw() {");
  typeWriter.addLine("  background(255);");
  typeWriter.addLine("");
  typeWriter.addLine("  typeWriter = typeWriter.update();");
  typeWriter.addLine("}");
  typeWriter.addLine("");
  typeWriter.addLine("ArrayList<String> lines = new ArrayList<String>();");
  typeWriter.addLine("");
  typeWriter.addLine("abstract class TypeWriter {");
  typeWriter.addLine("  int endPosition;");
  typeWriter.addLine("");
  typeWriter.addLine("  TypeWriter() {");
  typeWriter.addLine("    endPosition = 0;");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  public void addLine(String newLine) {");
  typeWriter.addLine("    addLines(newLine.split(\"\\n\"));");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  public void addLines(String[] newLines) {");
  typeWriter.addLine("    for(String line : newLines) lines.add(line);");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  protected int getAllStringLength() {");
  typeWriter.addLine("    int len = 0;");
  typeWriter.addLine("    for(String line : lines) len += line.length();");
  typeWriter.addLine("    return len;");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  TypeWriter update() {");
  typeWriter.addLine("    pushMatrix();");
  typeWriter.addLine("    camera();");
  typeWriter.addLine("    fill(0);");
  typeWriter.addLine("");
  typeWriter.addLine("    TypeWriter ret = display();");
  typeWriter.addLine("");
  typeWriter.addLine("    popMatrix();");
  typeWriter.addLine("    return ret;");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  protected abstract TypeWriter display();");
  typeWriter.addLine("}");
  */
}

