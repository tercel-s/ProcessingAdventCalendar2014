PImage g_WallImg;
PImage g_shoji;
PImage g_moon;
TypeWriter typeWriter;

State state;
void setup() {
  size(400, 300, P3D);
  frameRate(20);
  
  typeWriter = new Typer();
  g_WallImg = loadImage("bg.png");
  g_shoji = loadImage("shoji.png");
  g_moon = loadImage("moon.png");
  state = new Idle();
}

void draw() {
  if(g_WallImg.get(0, 0) == 0 || 
     g_shoji.get(0, 0)   == 0 ||
     g_moon.get(0, 0)    == 0) return;

  background(0);

  state = state.update();
  typeWriter = typeWriter.update();
  
}
