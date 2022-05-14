unit MessageUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.DateUtils, FMX.Layouts, FMX.Objects,
  FMX.Forms, FMX.Types, FMX.Graphics, FMX.StdCtrls, FMX.Ani,
  FMX.VirtualKeyboard, FMX.Platform;

type
  TMessage = class
  public
    class procedure Show(const Frm: TForm; Texto: String; Second : Integer = 2; CloseForm: Boolean = False);
    class procedure Close();

    class procedure Aguarde(const Frm: TForm; Texto: String; Second : Integer = 2);
    class procedure AguardeClose();

  end;

var
  // Aviso
  laMainForm    : TLayout;
  recBackground : TRectangle;
  Text          : TText;

  // Aguarde
  Layout   : TLayout;
  Fundo    : TRectangle;
  Arco     : TArc;
  Mensagem : TLabel;
  Animacao : TFloatAnimation;

implementation

{ TMessage }

class procedure TMessage.AguardeClose;
begin
  try
    if Assigned(Mensagem) then
      Mensagem.DisposeOf;

    if Assigned(Animacao) then
      Animacao.DisposeOf;

    if Assigned(Arco) then
      Arco.DisposeOf;

    if Assigned(Fundo) then
      Fundo.DisposeOf;

    if Assigned(Layout) then
      Layout.DisposeOf;
  except
  end;

  Mensagem := nil;
  Animacao := nil;
  Arco     := nil;
  Layout   := nil;
  Fundo    := nil;
end;

class procedure TMessage.Close;
begin
  try
    if Assigned(Text) then
      Text.DisposeOf;

    if Assigned(recBackground) then
      recBackground.DisposeOf;

    if Assigned(laMainForm) then
      laMainForm.DisposeOf;
  except
  end;

  Text          := nil;
  recBackground := nil;
  laMainForm    := nil;
end;

class procedure TMessage.Show(const Frm: TForm; Texto: String; Second: Integer; CloseForm: Boolean);
var timeNow, timeFinish : TTime;
begin
  if Frm <> nil then
  begin
    if not Assigned(laMainForm) then
      laMainForm := TLayout.Create(Frm);

    laMainForm.Parent  := Screen.ActiveForm;
    laMainForm.Align   := TAlignLayout.Contents;
    laMainForm.Visible := True;

    laMainForm.BringToFront;

    if not Assigned(recBackground) then
      recBackground := TRectangle.Create(laMainForm);

    recBackground.Align       := TAlignLayout.Client;
    recBackground.Parent      := laMainForm;
    recBackground.Opacity     := 0.7;
    recBackground.Stroke.Kind := TBrushKind.None;
    recBackground.Fill.Color  := TAlphaColorRec.Black;

    if not Assigned(Text) then
      Text := TText.Create(laMainForm);

    Text.Align                   := TAlignLayout.Center;
    Text.Parent                  := laMainForm;
    Text.Align                   := TAlignLayout.Client;
    Text.TextSettings.FontColor  := TAlphaColorRec.White;
    Text.TextSettings.Font.Size  := 26;
    //Text.TextSettings.Font.Style := [TFontStyle.fsBold];
    Text.TextSettings.WordWrap   := True;
    Text.Text                    := Texto;

    TThread.CreateAnonymousThread(procedure
    begin
      Sleep(300);
      TThread.Synchronize(nil, procedure begin laMainForm.Visible := True; end);

      timeNow    := time;
      timeFinish := time;
      timeFinish := IncSecond(timeFinish, Second);

      while (timeFinish >= timeNow) do
      begin
        Sleep(100);
        timeNow := time;
      end;

      TThread.Synchronize(nil, procedure
      begin
        laMainForm.Visible := False;
      end);

      Sleep( 350 );

      TThread.Synchronize(nil, procedure
      begin
        TMessage.Close;

        if CloseForm then
          Frm.Close;
      end);

    end).Start;
  end;
end;

class procedure TMessage.Aguarde(const Frm: TForm; Texto: String; Second: Integer);
var
  FService: IFMXVirtualKeyboardService;
  timeNow, timeFinish : TTime;
begin
  // Panel de fundo opaco...
  Fundo             := TRectangle.Create(Frm);
  Fundo.Opacity     := 0;
  Fundo.Parent      := Frm;
  Fundo.Visible     := true;
  Fundo.Align       := TAlignLayout.Contents;
  Fundo.Fill.Color  := TAlphaColorRec.Black;
  Fundo.Fill.Kind   := TBrushKind.Solid;
  Fundo.Stroke.Kind := TBrushKind.None;
  Fundo.Visible     := true;

  // Layout contendo o texto e o arco...
  Layout          := TLayout.Create(Frm);
  Layout.Opacity  := 0;
  Layout.Parent   := Frm;
  Layout.Visible  := true;
  Layout.Align    := TAlignLayout.Contents;
  Layout.Width    := 250;
  Layout.Height   := 78;
  Layout.Visible  := true;

  // Arco da animacao...
  Arco                  := TArc.Create(Frm);
  Arco.Visible          := true;
  Arco.Parent           := Layout;
  Arco.Align            := TAlignLayout.Center;
  Arco.Margins.Bottom   := 75; // 55
  Arco.Width            := 25;
  Arco.Height           := 25;
  Arco.EndAngle         := 280;
  Arco.Stroke.Color     := $FFFEFFFF;
  Arco.Stroke.Thickness := 2;
  Arco.Position.X       := trunc((Layout.Width - Arco.Width) / 2);
  Arco.Position.Y       := 0;

  // Animacao...
  Animacao               := TFloatAnimation.Create(Frm);
  Animacao.Parent        := Arco;
  Animacao.StartValue    := 0;
  Animacao.StopValue     := 360;
  Animacao.Duration      := 0.8;
  Animacao.Loop          := true;
  Animacao.PropertyName  := 'RotationAngle';
  Animacao.AnimationType := TAnimationType.InOut;
  Animacao.Interpolation := TInterpolationType.Linear;
  Animacao.Start;

  // Label do texto...
  Mensagem                        := TLabel.Create(Frm);
  Mensagem.Parent                 := Layout;
  Mensagem.Align                  := TAlignLayout.Center;
  Mensagem.Margins.Top            := 60;
  Mensagem.Font.Size              := 18;
  Mensagem.Height                 := 70;
  Mensagem.Width                  := Screen.ActiveForm.Width - 100;
  Mensagem.FontColor              := $FFFEFFFF;
  Mensagem.TextSettings.HorzAlign := TTextAlign.Center;
  Mensagem.TextSettings.VertAlign := TTextAlign.Leading;
  Mensagem.StyledSettings         := [TStyledSetting.Family, TStyledSetting.Style];
  Mensagem.Text                   := Texto;
  Mensagem.VertTextAlign          := TTextAlign.Leading;
  Mensagem.Trimming               := TTextTrimming.None;
  Mensagem.TabStop                := false;

  // Exibe os controles...
  Fundo.AnimateFloat('Opacity', 0.9);
  Layout.AnimateFloat('Opacity', 1);
  Layout.BringToFront;


  // Esconde o teclado virtual...
  TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService,
                                                    IInterface(FService));
  if (FService <> nil) then
      FService.HideVirtualKeyboard;

  FService := nil;

  TThread.CreateAnonymousThread(procedure
    begin
      Sleep(300);
      TThread.Synchronize(nil, procedure begin Fundo.Visible := True; end);

      timeNow    := time;
      timeFinish := time;
      timeFinish := IncSecond(timeFinish, Second);

      while (timeFinish >= timeNow) do
      begin
        Sleep(100);
        timeNow := time;
      end;

      TThread.Synchronize(nil, procedure
      begin
        Fundo.Visible := False;
      end);

      Sleep( 350 );

      TThread.Synchronize(nil, procedure
      begin
        TMessage.AguardeClose;
      end);

    end).Start;
end;

end.
