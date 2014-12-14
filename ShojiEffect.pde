



class Shoji {
  private final float FRAME_WIDTH = 6;
  private long counter;  
  private boolean opening;
  
  public boolean finished() {
    return !(counter < 0.5 * width);
  }
  
  Shoji(PImage _img, boolean opening) {
    this.img     = _img;
    this.opening = opening;
    frameImage = loadImage("frame.png");
    counter = 0;
    noStroke();
  }
  
  Shoji render() {
    this.opening = true;
    this.counter = 0;
    
    return this.update();
  }
  
  Shoji update() {
    if(img.get(0, 0) == 0 || frameImage.get(0, 0) == 0) return;
    
    float ratio = pow(min(2.0 * (float)counter / width, 1.0), 2);
    ratio = opening ? ratio : 1.0 - ratio;
    
    float x = ratio * (!opening ? (counter - 0.5 * width) : -counter);
    pushMatrix();
    translate(x, 0, 0);
    
    beginShape();
    texture(this.img);
    vertex(0, 0, 0, 0, 0);
    vertex(0, height, 0, 0, this.img.height);
    vertex(0.5 * width, height, 0, 0.5 * this.img.width, this.img.height);
    vertex(0.5 * width, 0 , 0, 0.5 * this.img.width, 0);
    endShape();
    
    for(float i = 0.5*(width - FRAME_WIDTH); !(i < 0); i -= 50) {
      beginShape();
      texture(frameImage);
      vertex(i - 0.5 * FRAME_WIDTH,      0, 1, i - 0.5 * FRAME_WIDTH,                 0);
      vertex(i - 0.5 * FRAME_WIDTH, height, 1, i - 0.5 * FRAME_WIDTH, frameImage.height);
      vertex(i + 0.5 * FRAME_WIDTH, height, 1, i + 0.5 * FRAME_WIDTH, frameImage.height);
      vertex(i + 0.5 * FRAME_WIDTH,      0, 1, i + 0.5 * FRAME_WIDTH,                 0);
      endShape();
    }
  
    for(int i = 0; (i < height); i += 60) {
      beginShape();
      texture(frameImage);
      vertex(          0, i - 0.5 * FRAME_WIDTH, 1,                0, i - 0.5 * FRAME_WIDTH);
      vertex(          0, i + 0.5 * FRAME_WIDTH, 1,                0, i + 0.5 * FRAME_WIDTH);
      vertex(0.5 * width, i + 0.5 * FRAME_WIDTH, 1, frameImage.width, i + 0.5 * FRAME_WIDTH);
      vertex(0.5 * width, i - 0.5 * FRAME_WIDTH, 1, frameImage.width, i - 0.5 * FRAME_WIDTH);
      endShape();
    }
    popMatrix();
    
    x = -x;
    pushMatrix();
    translate(x, 0, 0);
    beginShape();
    texture(this.img);
    vertex(0.5 * width, 0, 0, 0.5 * this.img.width, 0);
    vertex(0.5 * width, height, 0, 0.5 * this.img.width, this.img.height);
    vertex( width, height, 0, this.img.width, this.img.height);
    vertex( width, 0 , 0, this.img.width, 0);
    endShape();
    
    for(float i = width; !(i < 0.5 * width); i -= 50) {
      beginShape();
      texture(frameImage);
      vertex(i - 0.5 * FRAME_WIDTH,      0, 1, i - 0.5 * FRAME_WIDTH,                 0);
      vertex(i - 0.5 * FRAME_WIDTH, height, 1, i - 0.5 * FRAME_WIDTH, frameImage.height);
      vertex(i + 0.5 * FRAME_WIDTH, height, 1, i + 0.5 * FRAME_WIDTH, frameImage.height);
      vertex(i + 0.5 * FRAME_WIDTH,      0, 1, i + 0.5 * FRAME_WIDTH,                 0);
      endShape();
    }
  
    for(int i = 0; (i < height); i += 60) {
      beginShape();
      texture(frameImage);
      vertex(0.5 * width, i - 0.5 * FRAME_WIDTH, 1,                0, i - 0.5 * FRAME_WIDTH);
      vertex(0.5 * width, i + 0.5 * FRAME_WIDTH, 1,                0, i + 0.5 * FRAME_WIDTH);
      vertex(      width, i + 0.5 * FRAME_WIDTH, 1, frameImage.width, i + 0.5 * FRAME_WIDTH);
      vertex(      width, i - 0.5 * FRAME_WIDTH, 1, frameImage.width, i - 0.5 * FRAME_WIDTH);
      endShape();
    }
    popMatrix();
    counter += 10;
    return this;
  }
}
