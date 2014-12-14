PImage g_WallImg;
PImage g_shoji;
PImage g_moon;
PImage g_paper;
PImage g_hau;

TypeWriter typeWriter;

State state;
void setup() {
  size(400, 300, P3D);
  frameRate(20);
  
  typeWriter = new Typer();
  g_WallImg = loadImage("bg.png");
  g_shoji = loadImage("shoji.png");
  g_moon = loadImage("moon.png");
  g_paper = loadImage("paper.png");
  g_hau = loadImage("hau.png");
  state = new Idle();
}

void draw() {
  background(0);
  if(g_WallImg.get(0, 0) == 0 || 
     g_shoji.get(0, 0)   == 0 ||
     g_moon.get(0, 0)    == 0 ||
     g_paper.get(0, 0)   == 0 ||
     g_hau.get(0, 0)     == 0) return;

  state = state.update();
  typeWriter = typeWriter.update();
  
}
