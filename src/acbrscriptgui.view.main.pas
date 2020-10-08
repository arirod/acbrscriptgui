{
  acbrscriptgui
  Copyright (C) 2020 Ari Rodrigues
  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.
}


unit acbrscriptgui.view.main;

{$mode delphi}{$H+}

interface

uses
  LCLType,
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  ExtCtrls,
  EditBtn,
  StdCtrls,
  Buttons,
  SynEdit,
  ActnList,
  Math,
  process;

type

  { TFormMain }
  TFormMain = class(TForm)
    ActAbreForm: TAction;
    ActACBrCheckInstall: TAction;
    ActInstall: TAction;
    ActLazarusCheckInstall: TAction;
    ActionList1: TActionList;
    buttonDownload: TSpeedButton;
    edtPathACBr: TEditButton;
    edtPathLazarus: TEditButton;
    imagePowered: TImage;
    ImageList1: TImageList;
    lblACBrPath: TLabel;
    lblLazarusPath: TLabel;
    buttonValidatePathACBr: TSpeedButton;
    buttonValidatePathLazarus: TSpeedButton;
    outputScreen: TMemo;
    StaticText2: TLabel;
    verticalTitle: TLabel;
    PaintBox1: TPaintBox;
    PaintBox2: TPaintBox;
    BottomPanel: TPanel;
    pnlTop: TPanel;
    midTopPanel: TPanel;
    LeftPanel: TPanel;
    OutputPanel: TPanel;
    installButton: TSpeedButton;
    procedure ActAbreFormExecute(Sender: TObject);
    procedure ActACBrCheckInstallExecute(Sender: TObject);
    procedure ActInstallExecute(Sender: TObject);
    procedure ActLazarusCheckInstallExecute(Sender: TObject);
    procedure edtPathACBrButtonClick(Sender: TObject);
    procedure edtPathLazarusButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure outputScreenChange(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure PaintBox2Paint(Sender: TObject);
  private
    TimeOld: TDateTime;
    TimeFinish: TDateTime;
    strListACBr: TStringList;
    procedure ExecuteBuildIDE;
    procedure ExecuteAddPackges;
  public

  end;

var
  FormMain: TFormMain;
  FSplash: boolean = False;

implementation

{$R *.lfm}

uses
  {$IfNDef LINUX} Windows, {$EndIf}
  LCLIntf,
  FileUtil,
  acbrscriptgui.common,
  acbrscriptgui.model.downloadf,
  Keyboard;

procedure localiza(Sender: TObject);
var
  sDir: string;
begin
  SelectDirectory('Escolha a Pasta ', '', sDir);
  (Sender as TEditButton).Text := LowerCase(sDir);   /// ACBr <> acbr !!!!
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  buttonDownload.Caption := 'Atualize ou Instale pelo' + LineEnding +
    'download do ACBr - SVN' + LineEnding + '&Clique aqui';
  // FormMain.midTopPanel.Height:= {$IfNDef Windows} 100 {$Else} 90 {$IfEnd};
end;

procedure TFormMain.outputScreenChange(Sender: TObject);
begin
  Application.ProcessMessages;
  outputScreen.SelStart := Length(outputScreen.Text);
end;

procedure TFormMain.ActAbreFormExecute(Sender: TObject);
begin
  AbreForm(TFormDownload, FormDownload);
end;

procedure TFormMain.ActACBrCheckInstallExecute(Sender: TObject);
var
  i: integer = 0;
begin
  strListACBr := FindAllFiles(edtPathACBr.Text, '*.lpk', True);
  try
    for i := 0 to strListACBr.Count - 1 do
      outputScreen.Lines.Add(LowerCase(strListACBr.Strings[i]));
  finally
    buttonValidatePathACBr.ImageIndex := ifthen(i > 50, 4, 3);
  end;
end;

{ **************** InstallExecute **************** }
procedure TFormMain.ActInstallExecute(Sender: TObject);
begin
  if (buttonValidatePathACBr.ImageIndex = 3) or (buttonValidatePathLazarus.ImageIndex = 3) then
  begin
    dialogBoxAutoClose('', 'VALIDE SEU PATH NO ÍCONE VERMELHO', 4);
    exit;
  end;

  try
    TimeOld := Now;
    ExecuteAddPackges;
    ExecuteBuildIDE;
  finally
    TimeFinish := TimeOld - now;
    dialogBoxAutoClose('', 'ACBr FOI INSTALADO NO LAZARUS! ' + sLineBreak + TimeToStr(TimeFinish), 6);
    buttonValidatePathACBr.ImageIndex := 3;
    buttonValidatePathLazarus.ImageIndex := buttonValidatePathACBr.ImageIndex;

    outputScreen.Clear;
    outputScreen.Color := clCream;
    outputScreen.Font.Color := clBlack;
    edtPathACBr.Clear;
    edtPathLazarus.Clear;
  end;
end;

{ **************** AddPackges **************** }
procedure TFormMain.ExecuteAddPackges;
const
  C_BUFSIZE = 2048;
var
  AProcess: TProcess;
  Buffer: pointer;
  SStream: TStringStream;
  nread: longint;
  i: integer;
  fPath : string;
begin
  fPath := IncludeTrailingPathDelimiter(edtPathLazarus.Text) +'lazbuild';

  for i := 0 to strListACBr.Count - 1 do
  begin
    AProcess := TProcess.Create(nil);
    try
      AProcess.CommandLine:= concat(fPath,' --add-package-link ', strListACBr.Strings[i]);
      AProcess.Options := [poUsePipes, poStdErrToOutput];
      AProcess.ShowWindow := swoHIDE;
      ///
      Getmem(Buffer, C_BUFSIZE);
      SStream := TStringStream.Create('');
      ///
      AProcess.Execute;
      while AProcess.Running do
      begin
        nread := AProcess.Output.Read(Buffer^, C_BUFSIZE);
        if nread = 0 then
          sleep(100)
        else
        begin
          SStream.size := 0;
          SStream.Write(Buffer^, nread);
          { ...to do - verificar o porque nao esta dando saida em outputscreen}
          outputScreen.Lines.Append(SStream.DataString);
          outputScreen.Lines.Append(strListACBr.Strings[i]);
        end;
      end;

      repeat
        nread := AProcess.Output.Read(Buffer^, C_BUFSIZE);
        if nread > 0 then
        begin
          SStream.size := 0;
          SStream.Write(Buffer^, nread);
          outputScreen.Lines.Append(strListACBr.Strings[i]);
        end
      until nread = 0;

    finally
      AProcess.Free;
      Freemem(buffer);
      SStream.Free;
      Application.ProcessMessages;
    end;
  end; /// for in
end;

{ **************** ExecuteBuildIDE **************** }
procedure TFormMain.ExecuteBuildIDE;
const
  C_BUFSIZE = 2048;
var
  AProcess: TProcess;
  Buffer: pointer;
  SStream: TStringStream;
  nread: longint;
begin
  outputScreen.Clear;
  AProcess := TProcess.Create(nil);
  AProcess.Executable := IncludeTrailingPathDelimiter(edtPathLazarus.Text) + 'lazbuild';
  AProcess.Parameters.Add('--build-ide=');
  AProcess.Options := [poUsePipes, poStdErrToOutput];

  AProcess.ShowWindow := swoHIDE;
  Getmem(Buffer, C_BUFSIZE);
  SStream := TStringStream.Create('');
  ///
  AProcess.Execute;
  while AProcess.Running do
  begin
    nread := AProcess.Output.Read(Buffer^, C_BUFSIZE);
    if nread = 0 then
      sleep(100)
    else
    begin
      SStream.size := 0;
      SStream.Write(Buffer^, nread);
      outputScreen.Lines.Append(SStream.DataString);
    end;
  end;
  repeat
    nread := AProcess.Output.Read(Buffer^, C_BUFSIZE);
    if nread > 0 then
    begin
      SStream.size := 0;
      SStream.Write(Buffer^, nread);
      outputScreen.Lines.Append(SStream.DataString);
    end;
  until nread = 0;
  ///
  AProcess.Free;
  Freemem(buffer);
  SStream.Free;
end;

procedure TFormMain.ActLazarusCheckInstallExecute(Sender: TObject);
var
  sl: TStringList;
  i: integer =0 ;
begin
  outputScreen.Clear;
  sl := FindAllFiles(edtPathLazarus.Text, 'lazbuild.*', True);
  try
    for i := 0 to sl.Count - 1 do
      outputScreen.Lines.Add(LowerCase(sl.Strings[i]));
  finally
    buttonValidatePathLazarus.ImageIndex := ifthen(i >= 3, 4, 3);
    sl.Free;
  end;
end;

procedure TFormMain.edtPathACBrButtonClick(Sender: TObject);
begin
  localiza(edtPathACBr);
end;

procedure TFormMain.edtPathLazarusButtonClick(Sender: TObject);
begin
  localiza(edtPathLazarus);
end;


procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;


procedure TFormMain.FormDestroy(Sender: TObject);
begin
  strListACBr.Free;
  inherited;
end;

procedure TFormMain.PaintBox1Paint(Sender: TObject);
begin
  gradientHorizontal(PaintBox1.Canvas, PaintBox1.ClientRect, $60ff60, $00005300);
end;

procedure TFormMain.PaintBox2Paint(Sender: TObject);
begin
  gradientVertical(PaintBox2.Canvas, PaintBox2.ClientRect, $60ff60, $00005300);
end;


end.
