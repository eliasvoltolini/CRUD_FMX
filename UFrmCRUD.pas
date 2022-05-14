unit UFrmCRUD;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Math, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.VirtualKeyboard,
  FMX.Platform, FMX.TabControl, FMX.Ani, FMX.Edit,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Provider,
  Androidapi.JNIBridge, Androidapi.JNI.Telephony, Androidapi.JNI.JavaTypes,
  FMX.Helpers.Android, Androidapi.Helpers, Androidapi.Jni.Os,
  ToastMessage, MessageUnit;

type
  TMoveTab = (tmNone, tmBack, tmNext);
  TFrmCRUD = class(TForm)
    laMainForm    : TLayout;
    recMenu       : TRectangle;
    btnBack       : TSpeedButton;
    lbTitle       : TText;
    btnNext       : TSpeedButton;
    VertScrollBox : TVertScrollBox;
    tabControl    : TTabControl;
    tabN01        : TTabItem;
    procedure RestorePosition;
    procedure UpdateKBBounds;
    procedure DefineColorNotification(Color: TAlphaColor);
    procedure MoveTabControl(Action: TMoveTab); virtual;
    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
    procedure AnimationFinish(Sender: TObject); virtual;
    procedure PromptActive(Sender: TObject; Lab: TLabel; Animation: TFloatAnimation; Focus: Boolean = True); virtual;
    procedure ApplyMask(Sender: TObject; TypeMask: String); virtual;
    procedure DisplayTeclado(Sender: TEdit); virtual;
    procedure HideTeclado(); virtual;
    procedure FormCreate(Sender: TObject);
    procedure FormFocusChanged(Sender: TObject);
    procedure FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure btnBackClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
  private
    FKBBounds   : TRectF;
    FNeedOffset : Boolean;
  public
    { Public declarations }
  end;

var
  FrmCRUD: TFrmCRUD;

implementation

{$R *.fmx}

{ TFrmCRUD }

const
  CNT_COLOR_TOOLBAR_NOTIFICATION = $FF00435D;

procedure TFrmCRUD.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  TToastMessage.Close;
end;

procedure TFrmCRUD.FormCreate(Sender: TObject);
begin
  DefineColorNotification(CNT_COLOR_TOOLBAR_NOTIFICATION);

  VKAutoShowMode := TVKAutoShowMode.Always;
  VertScrollBox.OnCalcContentBounds := CalcContentBoundsProc;
  tabControl.ActiveTab := tabN01;
end;

procedure TFrmCRUD.FormFocusChanged(Sender: TObject);
begin
  UpdateKBBounds;
end;

procedure TFrmCRUD.FormKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
var FService : IFMXVirtualKeyboardService;
begin
  if (Key = vkHardwareBack) then
  begin
    TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService,
                                                      IInterface(FService));
    if (FService <> nil) And (TVirtualKeyboardState.Visible in
                              FService.VirtualKeyBoardState) then
    begin
    end
    else
    begin

      MoveTabControl( tmBack );

    end;
  end;
end;

procedure TFrmCRUD.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  HideTeclado();
end;

procedure TFrmCRUD.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := False;
  RestorePosition;
end;

procedure TFrmCRUD.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TFrmCRUD.MoveTabControl(Action: TMoveTab);
var
  iPosAtual : Integer;
  iPosNova  : Integer;
begin

  iPosAtual := tabControl.TabIndex;
  iPosNova  := iPosAtual;

  case Action of
    tmNone:
    begin

      iPosNova := iPosAtual;

    end;
    tmBack:
    begin

      if iPosAtual > 0 then
        iPosNova := tabControl.TabIndex - 1
      else
        Close;

    end;
    tmNext:
    begin

      if iPosAtual < tabControl.TabCount then
        iPosNova := tabControl.TabIndex + 1;

    end;
  end;

  tabControl.TabIndex := iPosNova;
end;

procedure TFrmCRUD.RestorePosition;
begin
  VertScrollBox.ViewportPosition := PointF(VertScrollBox.ViewportPosition.X, 0);
  laMainForm.Align := TAlignLayout.Client;
  VertScrollBox.RealignContent;
end;

procedure TFrmCRUD.UpdateKBBounds;
var
  LFocused : TControl;
  LFocusRect : TRectF;
begin
  FNeedOffset := False;
  if Assigned(Focused) then
  begin
    LFocused := TControl(Focused.GetObject);
    LFocusRect := LFocused.AbsoluteRect;
    LFocusRect.Offset(VertScrollBox.ViewportPosition);
    if (LFocusRect.IntersectsWith(TRectF.Create(FKBBounds))) And
       (LFocusRect.Bottom > FKBBounds.Top) then
    begin
      FNeedOffset := True;
      laMainForm.Align := TAlignLayout.Horizontal;
      VertScrollBox.RealignContent;
      Application.ProcessMessages;
      VertScrollBox.ViewportPosition :=
        PointF(VertScrollBox.ViewportPosition.X,
               LFocusRect.Bottom - FKBBounds.Top);
    end;
  end;
  if not FNeedOffset then
    RestorePosition;
end;

procedure TFrmCRUD.CalcContentBoundsProc(Sender: TObject;
  var ContentBounds: TRectF);
begin
  if (FNeedOffset) And (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom,
                                2 * ClientHeight - FKBBounds.Top);
  end;
end;

procedure TFrmCRUD.DefineColorNotification(Color: TAlphaColor);
begin
  CallInUIThreadAndWaitFinishing(
  procedure
  begin
    TAndroidHelper.Activity.getWindow.setStatusBarColor(Color);
  end);
end;

procedure TFrmCRUD.DisplayTeclado(Sender: TEdit);
var KeyboardService: IFMXVirtualKeyboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, IInterface(KeyboardService)) then
    KeyboardService.ShowVirtualKeyboard(Sender);
end;

procedure TFrmCRUD.HideTeclado;
var KeyboardService: IFMXVirtualKeyboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, IInterface(KeyboardService)) then
    KeyboardService.HideVirtualKeyboard;
end;

procedure TFrmCRUD.AnimationFinish(Sender: TObject);
begin
  TThread.Queue(nil,
    procedure
    begin
      if TFloatAnimation(Sender).Tag = 1 then
        TFloatAnimation(Sender).Tag := 0;

      TFloatAnimation(Sender).Inverse := not TFloatAnimation(Sender).Inverse;
    end);
end;

procedure TFrmCRUD.PromptActive(Sender: TObject; Lab: TLabel;
  Animation: TFloatAnimation; Focus: Boolean);
const cnt_tam_lab = 4;
begin
  TThread.Queue(nil,
    procedure
    var bStart : Boolean;
    begin
      bStart := True;
      if Animation.Inverse then
      begin
        if not Focus then
        begin
          if (Sender is TEdit) then
          begin
            if TEdit(Sender).Text <> EmptyStr then
              bStart := False;
          end;

          if bStart then
          begin
            Lab.Font.Size := Lab.Font.Size + cnt_tam_lab;
            Animation.Start;
          end;
        end;
      end
      else
      begin
        Lab.BringToFront;
        Lab.Font.Size := TEdit(Sender).Font.Size - cnt_tam_lab;

        Animation.Tag        := 1;
        Animation.Duration   := 0.15;
        Animation.Inverse    := False;
        Animation.StartValue := 0;
        Animation.StopValue  := TEdit(Sender).Font.Size + cnt_tam_lab;
        Animation.Start;
      end;

      if (Sender is TEdit) then
      begin
        if Focus then
        begin

          try
            if ActiveControl.Name <> TEdit(Sender).Name then
              Exit;

          except
            Exit;
          end;

        end;
      end;
    end);
end;

procedure TFrmCRUD.ApplyMask(Sender: TObject; TypeMask: String);
begin
  TThread.Queue(nil,
    procedure
    var
      M, V    : Integer;
      Texto   : String;
      Value   : String;
      Retorno : String;
      Mask    : String;
    begin
      Retorno  := EmptyStr;
      Texto    := EmptyStr;
      TypeMask := UpperCase(TypeMask);
      Value    := TEdit(Sender).Text;

      if TypeMask = 'DATA' then
        Mask := '##/##/####'
      else
      if TypeMask = 'CPF' then
        Mask := '###.###.###-##'
      else
      if TypeMask = 'CNPJ' then
        Mask := '##.###.###/####-##'
      else
      if TypeMask = 'FONE' then
        Mask := '(##) ####-####'
      else
      if TypeMask = 'CELULAR' then
        Mask := '(##) ####-#####'
      else
      if TypeMask = 'CEP' then
        Mask := '#####-###';

      Mask := Mask.ToUpper;

      for V := 0 to Pred(Value.Length) do
        if Value.Chars[V] In ['0'..'9'] Then
          Texto := Texto + Value.Chars[V];

      M := 0;
      V := 0;

      while (V < Texto.Length) And (M < Value.Length) do
      begin
        while Mask.Chars[M] <> '#' Do
        begin
          Retorno := Retorno + Mask.Chars[M];
          Inc(M);
        end;

        Retorno := Retorno + Texto.Chars[V];

        Inc(M);
        Inc(V);
      end;

       TEdit(Sender).Text := Retorno;
       TEdit(Sender).CaretPosition := TEdit(Sender).Text.Length;
    end);
end;

procedure TFrmCRUD.btnBackClick(Sender: TObject);
begin

  MoveTabControl( tmBack );

end;

procedure TFrmCRUD.btnNextClick(Sender: TObject);
begin

  MoveTabControl( tmNext );

end;

end.
