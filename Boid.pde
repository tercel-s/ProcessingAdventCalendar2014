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
