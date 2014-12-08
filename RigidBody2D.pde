/* Flocking */

final float THRUSTFORCE            = 3000.0f;
final float MAXTHRUST              = 4000.0f;
final float MINTHRUST              = 0.0f;
final float DTHRUST                = 10.0f;
final float STEERINGFORCE          = 500.f;
final float LINEARDRAGCOEFFICIENT  = 10.5f;
final float ANGULARDRAGCOEFFICIENT = 2000.0f;
 
class RigidBody2D {
  float mass;
  float inertia;
  float inertiaInverse;
   
  PVector position;         // 世界座標空間の位置
  PVector velocity;         // 　　　〃　　　速度
  PVector velocityBody;     // ローカル座標空間の速度
  PVector angularVelocity;  // 　　　　〃　　　　角速度
   
  float speed;              // 速さ（速度の大きさ）
  float orientation;        // オリエンテーション
   
  PVector forces;           // 力
  PVector moment;           // モーメント（Z軸まわりのみ）
   
  float thrustForce;        // 推力の大きさ
  PVector pThrust, sThrust; // 操舵力
   
  float width;
  float length;
  float height;
   
  PVector cd;
  PVector ct;
  PVector cpt;
  PVector cst;
   
  float projectedArea;
  PVector fa;
  PVector pa;
   
  boolean leader;
  boolean interceptor;
   
  RigidBody2D() {
    position        = new PVector();
    velocity        = new PVector();
    velocityBody    = new PVector();
    angularVelocity = new PVector();
     
    forces          = new PVector();
    moment          = new PVector();
     
    pThrust         = new PVector();
    sThrust         = new PVector();
     
    cd              = new PVector();
    ct              = new PVector();
    cpt             = new PVector();
    cst             = new PVector();
   
    fa              = new PVector();
    pa              = new PVector();
  }
   
  void calcLoads() {
    forces.set(0, 0, 0);
    moment.set(0, 0, 0);
     
    PVector fb     = new PVector();                  // 力の合計
    PVector mb     = new PVector();                  // モーメントの合計
    PVector thrust = new PVector(0.0f, 1.0f, 0.0f);  // 推進ベクトル
     
    thrust.mult(thrustForce);
     
    PVector localVelocity = new PVector();
    float   localSpeed;
    PVector dragVector = new PVector();
    float   tmp;
    PVector resultant = new PVector();
    PVector vtmp;
     
    vtmp = angularVelocity.cross(cd);
    localVelocity = PVector.add(velocityBody, vtmp);
     
    localSpeed = localVelocity.mag();
     
    if(localSpeed > tol) {
      localVelocity.normalize();
      dragVector.set(-localVelocity.x, -localVelocity.y, -localVelocity.z);
       
      float f;
      if(thrust.dot(localVelocity) / (thrust.mag() * localVelocity.mag()) > 0)
        f = 2;
      else
        f = 1;
         
      tmp = 0.5f * rho * localSpeed * localSpeed * projectedArea * f;
      resultant = PVector.mult(dragVector, LINEARDRAGCOEFFICIENT * tmp);
       
      fb.add(resultant);
       
      vtmp = cd.cross(resultant);
      mb.add(vtmp);
    }
     
    fb.add(PVector.mult(pThrust, 3));
     
    vtmp = cpt.cross(pThrust);
    mb.add(vtmp);
     
    fb.add(PVector.mult(sThrust, 3));
     
    vtmp = cst.cross(sThrust);
    mb.add(vtmp);
     
    fb.add(fa);
    vtmp = pa.cross(fa);
    mb.add(vtmp);
     
    if(angularVelocity.mag() > tol) {
      vtmp.x = 0;
      vtmp.y = 0;
      tmp = 0.5f * rho * angularVelocity.z * angularVelocity.z * projectedArea;
      if(angularVelocity.z > 0.0)
        vtmp.z = -ANGULARDRAGCOEFFICIENT * tmp;
      else
        vtmp.z = ANGULARDRAGCOEFFICIENT * tmp;
      mb.add(vtmp);
    }
     
    fb.add(thrust);
    forces = rotate2D(orientation, fb);
    moment.add(mb);
  }
   
  void updateBodyEuler(float dt) {
    // 力とモーメントの計算
    calcLoads();
     
    PVector a = PVector.div(forces, mass);
     
    PVector dv = PVector.mult(a, dt);
    velocity.add(dv);
     
    PVector ds = PVector.mult(velocity, dt);
    position.add(ds);
     
    float aa  = moment.z / inertia;
    float dav = aa * dt;
    angularVelocity.z += dav;
     
    float dr = angularVelocity.z * dt;
    orientation += dr;
     
    speed = velocity.mag();
    velocityBody = rotate2D(-orientation, velocity);
  }
   
  void setThrusters(boolean p, boolean s, float f) {
    pThrust.x = 0;
    pThrust.y = 0;
    sThrust.x = 0;
    sThrust.y = 0;
     
    if(p) pThrust.x = -STEERINGFORCE * f;
    if(s) sThrust.x =  STEERINGFORCE * f;
  }
   
  void modulateThrust(boolean up) {
    float dT = up ? DTHRUST : -DTHRUST;
    thrustForce += dT;
     
    if(thrustForce > MAXTHRUST) thrustForce = MAXTHRUST;
    if(thrustForce < MINTHRUST) thrustForce = MINTHRUST;
  }
}
 
PVector rotate2D(float angle, PVector u) {
  float x, y;
  x =  u.x * cos(-angle) + u.y * sin(-angle);
  y = -u.x * sin(-angle) + u.y * cos(-angle);
  return new PVector(x, y);
}
