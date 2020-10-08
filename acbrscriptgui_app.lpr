program acbrscriptgui_app;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  acbrscriptgui.view.main,
  acbrscriptgui.common,
  acbrscriptgui.model.downloadf;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  //Application.CreateForm(TFormTestListbox, FormTestListbox);
  //Application.CreateForm(TForm2, Form2);
  Application.Run;
end.

