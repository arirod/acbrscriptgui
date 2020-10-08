unit acbrscriptgui.common;

{$mode objfpc} {$H+}

interface

uses
   {$IfNDef LINUX} Windows, {$EndIf} //TTimeZoneInformation
  Classes,
  SysUtils,
  DB,
  Types,  // TSize
  Forms,
  LCLIntf,
  LCLType,
  registry,
  Math,
  Controls,
  DBCtrls,
  Graphics,
  StdCtrls,
  Dialogs,
  IniFiles;

{ procedures }
procedure Aviso(const m: string; const t: cardinal = 1000);
procedure gradientHorizontal(Canvas: TCanvas; Rect: TRect; FromColor, ToColor: TColor);
procedure gradientVertical(Canvas: TCanvas; Rect: TRect; FromColor, ToColor: TColor);
procedure DialogBoxAutoClose(const ACaption, APrompt: string; DuracaoEmSegundos: integer);
procedure gravarIni(sArquivo, sSecao, sComponente, sValor: string);
procedure AbreForm(aClasseForm: TComponentClass; aForm: TForm);

{ functions }
function ler_ini(sInifile, sSecao, sChave: string): string;

{ ** implementation ** }
implementation


procedure AbreForm(aClasseForm: TComponentClass; aForm: TForm);
begin
  Application.CreateForm(aClasseForm, aForm);
  try
    aForm.ShowModal;
  finally
    FreeAndNil(aForm);
  end;
end;


procedure Aviso(const m: string; const t: cardinal = 1000);
var
  P: TPoint;
  R: TRect;
  X: integer;
begin
  GetCursorPos(P);
  with THintWindow.Create(Application) do
    try
      // Application.HintColor := clSkyBlue;
      R := CalcHintRect(Screen.Width, m, nil);
      X := R.Right - R.Left + 1;
      R.Left := P.X;
      R.Right := R.Left + X;

      X := R.Bottom - R.Top + 1;
      R.Top := P.Y - X;
      R.Bottom := R.Top + X;

      ActivateHint(R, m);
      Update;
      Sleep(t);
    finally
      Free;
    end;
end;

procedure gradientHorizontal(Canvas: TCanvas; Rect: TRect; FromColor, ToColor: TColor);
var
  X: integer;
  dr, dg, DB: extended;

  C1, C2: TColor;
  r1, r2, g1, g2, b1, b2: byte;
  R, G, B: byte;
  cnt: integer;
begin
  C1 := FromColor;
  r1 := GetRValue(C1);
  g1 := GetGValue(C1);
  b1 := GetBValue(C1);

  C2 := ToColor;
  r2 := GetRValue(C2);
  g2 := GetGValue(C2);
  b2 := GetBValue(C2);

  dr := (r2 - r1) / Rect.Right - Rect.Left;
  dg := (g2 - g1) / Rect.Right - Rect.Left;
  DB := (b2 - b1) / Rect.Right - Rect.Left;

  cnt := 0;
  for X := Rect.Left to Rect.Right - 1 do
  begin
    R := r1 + Ceil(dr * cnt);
    G := g1 + Ceil(dg * cnt);
    B := b1 + Ceil(DB * cnt);

    Canvas.Pen.Color := RGB(R, G, B);
    Canvas.MoveTo(X, Rect.Top);
    Canvas.LineTo(X, Rect.Bottom);
    Inc(cnt);
  end;
end;

procedure gradientVertical(Canvas: TCanvas; Rect: TRect; FromColor, ToColor: TColor);
var
  Y: integer;
  dr, dg, DB: extended;
  C1, C2: TColor;
  r1, r2, g1, g2, b1, b2: byte;
  R, G, B: byte;
  cnt: integer;
begin
  C1 := FromColor;
  r1 := GetRValue(C1);
  g1 := GetGValue(C1);
  b1 := GetBValue(C1);

  C2 := ToColor;
  r2 := GetRValue(C2);
  g2 := GetGValue(C2);
  b2 := GetBValue(C2);

  dr := (r2 - r1) / Rect.Bottom - Rect.Top;
  dg := (g2 - g1) / Rect.Bottom - Rect.Top;
  DB := (b2 - b1) / Rect.Bottom - Rect.Top;

  cnt := 0;
  for Y := Rect.Top to Rect.Bottom - 1 do
  begin
    R := r1 + Ceil(dr * cnt);
    G := g1 + Ceil(dg * cnt);
    B := b1 + Ceil(DB * cnt);

    Canvas.Pen.Color := RGB(R, G, B);
    Canvas.MoveTo(Rect.Left, Y);
    Canvas.LineTo(Rect.Right, Y);
    Inc(cnt);
  end;
end;



// http://stackoverflow.com/questions/4472215/close-delphi-dialog-after-x-seconds

procedure dialogBoxAutoClose(const ACaption, APrompt: string; DuracaoEmSegundos: integer);
var
  Form: TForm;
  Prompt: TLabel;
  DialogUnits: TPoint;
  ButtonTop, ButtonWidth, ButtonHeight: integer;
  nX, Lines: integer;

  function GetAveCharSize(Canvas: TCanvas): TPoint;
  var
    i: integer;
    Buffer: array [0 .. 51] of char;
  begin
    for i := 0 to 25 do
      Buffer[i] := Chr(i + Ord('A'));
    for i := 0 to 25 do
      Buffer[i + 26] := Chr(i + Ord('a'));
    GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
    Result.X := Result.X div 52;
  end;

begin
  Form := TForm.Create(Application);
  Lines := 0;

  for nX := 1 to Length(APrompt) do
    if APrompt[nX] = #13 then
      Inc(Lines);

  with Form do
    try
      Font.Name := 'Arial'; // mcg
      Font.Size := 10; // mcg
      Font.Style := [fsBold]+[fsItalic];
      Canvas.Font := Font;
      DialogUnits := GetAveCharSize(Canvas);
      BorderStyle    := bsSingle;
      Color          := clYellow;
      BorderStyle := bsNone{bsToolWindow};
      FormStyle := fsStayOnTop;
      BorderIcons := [];
      Caption := ACaption;
      ClientWidth := MulDiv(Screen.Width div 4, DialogUnits.X, 4);
      ClientHeight := MulDiv(23 + (Lines * 10), DialogUnits.Y, 8);
      Position := poScreenCenter;
      Position := poOwnerFormCenter;

      Prompt := TLabel.Create(Form);
      with Prompt do
      begin
        Parent := Form;
        AutoSize := True;

        Alignment := taCenter;
        Align:=alClient;
        BorderSpacing.Top:=15;

        Left := MulDiv(8, DialogUnits.X, 4);
        Top := MulDiv(8, DialogUnits.Y, 8);
        Caption := APrompt;
      end;

      Form.Width := Prompt.Width + Prompt.Left + 300; // mcg fix

      Show;
      Application.ProcessMessages;
    finally
      Sleep(DuracaoEmSegundos * 1000);
      Form.Free;
    end;
end;


procedure gravarIni(sArquivo, sSecao, sComponente, sValor: string);
var
  iArq: TIniFile;
begin
  iArq := TIniFile.Create(ExtractFilePath(Application.ExeName) + sArquivo);
  iArq.WriteString(sSecao, sComponente, sValor);
  iArq.Free;
end;

function ler_ini(sInifile, sSecao, sChave: string): string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + sInifile);
  try
    Result := Ini.ReadString(sSecao, sChave, '');
  finally
    Ini.Free
  end;
end;


// ********************** Final da Lib ***************
end.
