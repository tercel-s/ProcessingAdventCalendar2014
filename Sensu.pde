class SensuEffect implements State {
  private State[] sensuArray;
  private int counter;
  private Seigaiha seigaiha;
  private PImage backgroundImg;
  private PImage paperImg;
  SensuEffect() {
    sensuArray = new Sensu[4];
    counter = 0;
    this.seigaiha = seigaiha;
    
    seigaiha = new Seigaiha();    
    backgroundImg = loadImage("seigaiha.png");
    paperImg   = g_paper;
  }
    
  State update() {   
    if(backgroundImg.get(0, 0) == 0) return this;
    
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
    
    return seigaiha.finished() ? new Mosaic2(backgroundImg, paperImg, 2, new OrigamiEffect()) : this;
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
