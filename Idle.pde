class Idle implements State {
  Shoji _shoji;
  Idle() {
    _shoji = new Shoji(loadImage("shoji.png"), false);
  }
  
  State update() {
    _shoji.render();
    if(!mousePressed) return this;
    return new Boid();
  }
}
