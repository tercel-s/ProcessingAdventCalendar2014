boolean wideView    = false;  // 視野: 広い
boolean limitedView = false;  //     : そこそこ
boolean narrowView  = false;  //     : 狭い
 
boolean chase       = false;  // 追跡モード
class Boid implements State {
  private int _counter;
  private Shoji _shoji;
  private PImage _bg;
  Boid() {
    _counter = 0;
    _bg = g_moon;
    _shoji = new Shoji(g_shoji, true);
    setupTypeWriter();
    initialize();
    
    wideView = true;
  }
  
  State update() {
    if(_bg.get(0, 0) == 0) return this;
    
    pushMatrix();
    translate(1.5 * _counter, 0, 2.5 * _counter);
    drawBackground(_bg);
    popMatrix();
    
    pushMatrix();
    translate(0, 0, -20);
    updateSimulation();
    popMatrix();
    
    _shoji = _shoji.update();
    
    if(++_counter < 220) return this;
    
    return new LogoDisplay();
  }
}
