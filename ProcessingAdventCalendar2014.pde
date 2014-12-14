PImage  img;
TypeWriter typeWriter;

State state;
void setup() {
  size(400, 300, P3D);
  frameRate(20);
  
  typeWriter = new Typer();
  img = loadImage("bg.png");  
  state = new Idle();
  g_Counter = 0;
}

void draw() {
  if(img.get(0, 0) == 0) return;

  background(0);

  state = state.update();
  typeWriter = typeWriter.update();
  
}
