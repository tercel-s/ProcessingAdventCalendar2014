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
