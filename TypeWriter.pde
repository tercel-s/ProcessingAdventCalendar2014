ArrayList<String> lines = new ArrayList<String>();
abstract class TypeWriter {
  
  final int MAX_LINES =  5;
  final int FONT_SIZE = 12;
  final int WAIT_TIME = 12;
  final int START_X = 3;
  final int START_Y = 3 + FONT_SIZE;
  final color FONT_COLOR = 0xFFFFFFFF;
  
  final color CARET_INACTIVE_COLOR = 0xFFFFFFFF;
  final color CARET_ACTIVE_COLOR   = 0xFF7F7F7F;
  
  final int CARET_INTERVAL = 5;
  
  int _endPosition;
  
  TypeWriter() {
    _endPosition = 0;
  }
  
  public void addLine(String newLine) {
    addLines(newLine.split("¥n"));
  }
  
  public void addLines(String[] newLines) {
    for(String line : newLines) lines.add(line);
  }
  
  protected int getAllStringLength() {
    int len = 0;
    for(String line : lines) len += line.length();
    return len;
  }
  
  // テンプレートメソッド的な
  TypeWriter update() {
    pushMatrix();

    camera();
    textSize(FONT_SIZE);
    fill(FONT_COLOR);
    
    
    // サブクラスの具象メソッドに委譲
    TypeWriter ret = display();
    
    popMatrix();
    return ret;
  }
  
  // 抽象メソッド
  protected abstract TypeWriter display();
  
  // キャレットを描画
  protected void drawCaret(float x, float y) {
    int caretColor = CARET_INTERVAL - (frameCount % (2 * CARET_INTERVAL)) < 0 ?
      CARET_ACTIVE_COLOR : CARET_INACTIVE_COLOR;
      
    fill(caretColor);
    noStroke();
    text("■", x, y);
    fill(FONT_COLOR);
  }
  
  protected PVector getCaretPos() {
    int textLength = _endPosition;
    for(int i = 0; i < lines.size(); ++i) {
      String str = lines.get(i);
      if(textLength == 0) {
        return new PVector(START_X, 
                          (str.length() == 0 ? (i + 1) : i) * FONT_SIZE + START_Y);
      }
      if(textLength < str.length()) {
        return new PVector(START_X + textWidth(str.substring(0, textLength+1)),
                           START_Y + i * FONT_SIZE);
      }
      textLength -= str.length();
    }
    
    return new PVector(-999, -999);
  }
}

// 文字を打ち出す人
class Typer extends TypeWriter {
  Typer() { this(0); }
  
  Typer(int endPosition) {
    _endPosition = endPosition;
  }
  
  protected TypeWriter display() {
    if(getAllStringLength() == 0) {
      _endPosition = 0;
      return this;
    }
    
    PVector caretPos = getCaretPos();
    drawCaret(caretPos.x, caretPos.y);
    
    int textLength = ++_endPosition;    
    for(int i = 0; i < min(MAX_LINES, lines.size()); ++i) {
      String line = (textLength < lines.get(i).length()) ? 
        lines.get(i).substring(0, textLength) : lines.get(i);
      
      text(line, START_X, START_Y + i * FONT_SIZE);
      textLength -= line.length();
      if(!(0 < textLength)) {
        return this;
      }
    }

    return new Waiter(_endPosition -1);
  }
}

// 待つ人
class Waiter extends TypeWriter {
  int _counter;
  Waiter(int endPosition) {
    _counter = 0;
    _endPosition = endPosition;
  }
  
  protected TypeWriter display() {
    ++_counter;
    for(int i = 0; i < min(MAX_LINES, lines.size()); ++i) {
      String line = lines.get(i);
      text(line, START_X, START_Y + i * FONT_SIZE);
    }
    
    PVector caretPos = getCaretPos();
    drawCaret(caretPos.x, caretPos.y);
    
    return WAIT_TIME < _counter || _endPosition < getAllStringLength() ?
      new Elevator(_endPosition) : this;
  }
}

// 位置を送る人
class Elevator extends TypeWriter {
  int _counter;
  Elevator(int endPosition) {
    _endPosition = endPosition;
    _counter = 0;
  }
  
  protected TypeWriter display() {
    int textLength = ++_endPosition - lines.get(0).length();
    
      PVector caretPos = getCaretPos();
      drawCaret(caretPos.x, caretPos.y);
    
    // 1行目がなめらかに消えるように、
    // 縦方向に縮小するアニメーションを行う。
    if(++_counter < FONT_SIZE) {
      float scaleFactor = 1.0 - _counter / (float)FONT_SIZE;
      pushMatrix();
      translate(0,  FONT_SIZE * 0.5);
      scale(1.0, scaleFactor, 1.0);
      translate(0, - FONT_SIZE * 0.5);
      text(lines.get(0), START_X, START_Y);    
      popMatrix();
    }
    
    // 2行目以降の表示
    for(int i = 1; i < min(MAX_LINES, lines.size()); ++i) {
      String line = lines.get(i);
      textLength -= line.length();
      text(line, START_X, START_Y + i * FONT_SIZE - _counter);
    }
    
    if (0 < textLength && MAX_LINES < lines.size()) {
      String line = textLength < lines.get(MAX_LINES).length() ?
        lines.get(MAX_LINES).substring(0, textLength) : lines.get(MAX_LINES);      
      text(line, START_X, START_Y + (MAX_LINES) * FONT_SIZE - _counter);
    } else  --_endPosition;

    if(_counter < FONT_SIZE) {
      return this;
    }
    _endPosition -= lines.get(0).length();    
    if(MAX_LINES < lines.size() && 
       lines.get(MAX_LINES).length() < textLength)
         _endPosition -= (textLength - lines.get(MAX_LINES).length());

    lines.remove(0);
    return new Typer(_endPosition);
  }
  
  // オーバーライド
  protected PVector getCaretPos() {
    int textLength = _endPosition;
    int i;
    String line = "";
    for(i = 1; i < min(MAX_LINES, lines.size()); ++i) {
      line = lines.get(i);
      textLength -= line.length();
    }
    
    if (0 < textLength && MAX_LINES < lines.size()) {
      line = _counter < lines.get(MAX_LINES).length() ?
        lines.get(MAX_LINES).substring(0, _counter +1) : lines.get(MAX_LINES); 
        
      return line.equals(lines.get(MAX_LINES)) ?
        new PVector(START_X, 
                    START_Y + (MAX_LINES + 1) * FONT_SIZE - _counter) :
        new PVector(START_X + textWidth(line), 
                    START_Y + MAX_LINES * FONT_SIZE - _counter);
    }
    
    return new PVector(START_X, 
                       START_Y + (i + 1) * FONT_SIZE - _counter);
  }
}

void setupTypeWriter() {
  typeWriter.addLine("Processing Advent Calendar 2014");
  typeWriter.addLine("");
  typeWriter.addLine("Dec 15th 2014");
  typeWriter.addLine("");
  typeWriter.addLine("Presented by Tercel");
  typeWriter.addLine("");
  typeWriter.addLine("");
  typeWriter.addLine("void setup() {");
  typeWriter.addLine("  size(400, 300, P3D);");
  typeWriter.addLine("  typeWriter = new Typer();");
  typeWriter.addLine("  frameRate(20);");
  typeWriter.addLine("  setupTypeWriter();");
  typeWriter.addLine("}");

  /*
  typeWriter.addLine("");
  typeWriter.addLine("void draw() {");
  typeWriter.addLine("  background(255);");
  typeWriter.addLine("");
  typeWriter.addLine("  typeWriter = typeWriter.update();");
  typeWriter.addLine("}");
  typeWriter.addLine("");
  typeWriter.addLine("ArrayList<String> lines = new ArrayList<String>();");
  typeWriter.addLine("");
  typeWriter.addLine("abstract class TypeWriter {");
  typeWriter.addLine("  int endPosition;");
  typeWriter.addLine("");
  typeWriter.addLine("  TypeWriter() {");
  typeWriter.addLine("    endPosition = 0;");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  public void addLine(String newLine) {");
  typeWriter.addLine("    addLines(newLine.split(\"\\n\"));");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  public void addLines(String[] newLines) {");
  typeWriter.addLine("    for(String line : newLines) lines.add(line);");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  protected int getAllStringLength() {");
  typeWriter.addLine("    int len = 0;");
  typeWriter.addLine("    for(String line : lines) len += line.length();");
  typeWriter.addLine("    return len;");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  TypeWriter update() {");
  typeWriter.addLine("    pushMatrix();");
  typeWriter.addLine("    camera();");
  typeWriter.addLine("    fill(0);");
  typeWriter.addLine("");
  typeWriter.addLine("    TypeWriter ret = display();");
  typeWriter.addLine("");
  typeWriter.addLine("    popMatrix();");
  typeWriter.addLine("    return ret;");
  typeWriter.addLine("  }");
  typeWriter.addLine("");
  typeWriter.addLine("  protected abstract TypeWriter display();");
  typeWriter.addLine("}");
  */
}
