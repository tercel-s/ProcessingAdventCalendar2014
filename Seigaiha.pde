float FAR_CLIP = 1000;
float PATTERN_SIZE = 101;

// 描画が終わったパターンの数をかぞえるよ
int seigaihaPatternCounter;

class Seigaiha {
  ArrayList<Row> rows;
  private long counter;
  // private boolean finished;
  Seigaiha() {
    rows = new ArrayList<Row>();
    counter = 0;
    seigaihaPatternCounter = 0;
  }
  
  long getNumPatterns() {
    return (long)(height / (0.25 * PATTERN_SIZE) + 1) * rows.get(0).getNumPatterns();
  }
  
  boolean finished() {
    return seigaihaPatternCounter > getNumPatterns();
  }
  
  Seigaiha update() {
    camera();
    
    // カメラ焦点距離
    final float FOCAL_LENGTH = height * 0.5 / tan(PI / 6.0);
  
    translate( 0.5 * width,  0.5 * height, -FAR_CLIP);
    scale((FOCAL_LENGTH + abs(FAR_CLIP)) / FOCAL_LENGTH);
    translate(-0.5 * width, -0.5 * height, 0);
    
    if(rows.size() == 0) {
      rows.add(new Row(height + 0.25 * PATTERN_SIZE));
    }
    
    if((++counter % (int)(4 * rows.get(0).getNumPatterns())) == 0) {
      if(rows.size() < height / (0.25 * PATTERN_SIZE) + 1) {
        rows.add(new Row(height + (1 - rows.size()) * 0.25 * PATTERN_SIZE));
      } 
    }
    
    for(int i = rows.size()-1; !(i < 0); --i) {
      pushMatrix();
      if(i % 2 != 0) {
        translate(0.5 * PATTERN_SIZE, 0);
      }
      translate(0, 0, -i);
      rows.set(i, rows.get(i).update());
      
      popMatrix();
    }
    
    noStroke();
    return this;
  }
}

class Row {
  ArrayList<Pattern> patterns;
  private long counter;
  private float y;
  Row(float y) {
    patterns = new ArrayList<Pattern>();
    counter  = 0;
    this.y   = y;
  }
  
  long getNumPatterns() {
    return (long)(width / PATTERN_SIZE + 1);
  }
  
  Row update() {
    if(counter++ % 4 == 0) {
      if (patterns.size() < getNumPatterns()) {
        patterns.add(new Pattern(patterns.size() * PATTERN_SIZE, y));
      }
    }
    for(int i = 0; i < patterns.size(); ++i) {
      patterns.set(i, patterns.get(i).update());
    }
    return this;
  }
}

class Pattern {
  private long counter;
  private float x, y;
  private final float SPEED = 10.0;
  private boolean finished;
  
  Pattern(float x, float y) {
    this.x = x;
    this.y = y;
    finished = false;
  }
  
  float getSize() {
    return PATTERN_SIZE;
  }
  
  Pattern update() {
    float angle = min(SPEED * radians(counter), PI);

    noFill();
    fill(0);
    stroke(0xFF00CCFF);
    for(float r = PATTERN_SIZE; !(r < 0); r -= 15) {
      if(angle < PI) {
        arc(x, y, r, r, PI, PI+angle);
      } else {
        if(!finished) {
          ++seigaihaPatternCounter;
          finished = true;
        }
        ellipse(x, y, r, r);
      }
      noFill();
    }
    noStroke();
    
    ++counter;
    return this;
  }
}
