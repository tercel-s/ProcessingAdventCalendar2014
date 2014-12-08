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
    
    if(blackImg.get(0,0) == 0) return;
    
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
