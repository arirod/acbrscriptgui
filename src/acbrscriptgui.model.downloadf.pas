{
  SVNClasses
  Copyright (C) 2008 Darius Blaszijk
  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.
}

unit acbrscriptgui.model.downloadf;

{$mode objfpc}{$H+}

interface


//////svn co https://lazarus-ccr.svn.sourceforge.net/svnroot/lazarus-ccr/applications/fpsvnsync

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  StdCtrls,
  ExtCtrls,
  EditBtn,
  ComCtrls,
  Buttons,
  ///
  LCLProc,    ///   debugln
  SVNClasses, ///  incluir o path no projeto ..\components\lazsvnpkg
  UTF8Process,
  Process,
  FileUtil;

type

  { TFormDownload }

  TFormDownload = class(TForm)
    btnDownload: TSpeedButton;
    DownloadPath: TEditButton;
    labelDownloadPath: TLabel;
    labelRepositoryURL: TLabel;
    panelTop: TPanel;
    SVNUpdateListView: TListView;
    procedure btnDownloadClick(Sender: TObject);
    procedure DownloadPathButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public
    { public declarations }
    procedure Execute({%H-}Data: PtrInt);
    procedure ProcessSVNUpdateOutput(var MemStream: TMemoryStream; var BytesRead: longint);
  end;

var
  FormDownload: TFormDownload;

implementation

{$R *.lfm}

procedure TFormDownload.FormCreate(Sender: TObject);
begin
  SetColumn(SVNUpdateListView, 0, 75, rsAction);
  SetColumn(SVNUpdateListView, 1, 400, rsPath);
end;

procedure TFormDownload.btnDownloadClick(Sender: TObject);
begin
  Application.QueueAsyncCall(@Execute, 0);
end;

procedure TFormDownload.DownloadPathButtonClick(Sender: TObject);
var
  sDir: string;
begin
  SelectDirectory('Escolha a Pasta para Download', '', sDir);
  DownloadPath.Text := LowerCase(sDir);
end;



procedure TFormDownload.FormShow(Sender: TObject);
begin
  Caption := Format(rsLazarusSVNUpdate, [labelRepositoryURL.Caption]);
end;

procedure TFormDownload.Execute(Data: PtrInt);
var
  AProcess: TProcessUTF8;
  n: longint;
  MemStream: TMemoryStream;
  BytesRead: longint;
begin
  SVNUpdateListView.Clear;

  MemStream := TMemoryStream.Create;
  BytesRead := 0;
  {   /home/aeondc/lazarus-projetos/acbr/trunk2/  }
  AProcess := TProcessUTF8.Create(nil);
  try
    AProcess.Executable := {$IfNDef LINUX} '"svn.exe"' {$Else} 'svn'{$EndIf};
    AProcess.Parameters.Add('checkout');
    AProcess.Parameters.Add(labelRepositoryURL.Caption);
    AProcess.Parameters.Add(DownloadPath.Text);
    AProcess.Options := [poUsePipes, poStdErrToOutput];
    AProcess.ShowWindow := swoHIDE;
    AProcess.Execute;
    ////
    while AProcess.Running do
    begin
      MemStream.SetSize(BytesRead + READ_BYTES);
      n := AProcess.Output.Read((MemStream.Memory + BytesRead)^, READ_BYTES);
      if n > 0 then
      begin
        Inc(BytesRead, n);
        ProcessSVNUpdateOutput(MemStream, BytesRead);
      end
      else
        Sleep(100);
    end;
    ///
    repeat
      MemStream.SetSize(BytesRead + READ_BYTES);
      n := AProcess.Output.Read((MemStream.Memory + BytesRead)^, READ_BYTES);
      if n > 0 then
      begin
        Inc(BytesRead, n);
        ProcessSVNUpdateOutput(MemStream, BytesRead);
      end;
    until n <= 0;

  finally
    AProcess.Free;
    MemStream.Free;
  end;
end;

procedure TFormDownload.ProcessSVNUpdateOutput(var MemStream: TMemoryStream; var BytesRead: longint);
var
  S: TStringList;
  n: longint;
  i: integer;
  str: string;
begin
  Memstream.SetSize(BytesRead);
  S := TStringList.Create;
  S.LoadFromStream(MemStream);

  for n := 0 to S.Count - 1 do
    with SVNUpdateListView.Items.Add do
    begin
      //find position of first space character
      i := pos(' ', S[n]);
      str := Copy(S[n], 1, i - 1);

      if str = 'A' then
        str := rsAdded;
      if str = 'D' then
        str := rsDeleted;
      if str = 'U' then
        str := rsUpdated;
      if str = 'C' then
        str := rsConflict;
      if str = 'G' then
        str := rsMerged;
      Caption := str;

      Subitems.Add(Trim(Copy(S[n], i, Length(S[n]) - i + 1)));
    end;

  S.Free;
  BytesRead := 0;
  MemStream.Clear;

  SVNUpdateListView.Items[SVNUpdateListView.Items.Count - 1].MakeVisible(True);

  //repaint the listview
  Application.ProcessMessages;
end;



end.
