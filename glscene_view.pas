unit glscene_view;
// 3D-Visualisierung der Fr�swege und Bohrl�cher f�r GRBLize CNC-Steuerung
// Verwendet GLscene-Komponente als OpenGL-Interface

// Finite-Elemente-Fr�ssimulation legt ein zweidimensionales Array
// mit n-facher Aufl�sung pro mm (Integer) an, jede Zelle enth�lt im
// Grundzustand 0, d.h. Oberfl�che des Werkst�cks.
// Des weiteren ein kleineres Array, das die Werkzeugspitze simuliert.
// Ist der Inhalt des Werkzeug-Arrays kleiner als der Inhalt der korrespondierenden
// Oberfl�chen-Arrays, wird dessen Wert auf den Werkzeugspitzen-Array-Wert gesetzt.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Registry, import_files, ComCtrls,
  drawing_window, Clipper,
  //nVIDIA
  Cg, cgGL,
  //GLS
  GLCadencer, GLWin32Viewer, GLObjects, GLGraph, GLScene, GLVectorGeometry, GLVectorTypes,
  GLCrossPlatform, GLCoordinates, GLBaseClasses,  GLKeyboard,

  GLTexture, GLCgShader,
  GLVectorFileObjects, GLFile3DS, GLMaterial,
  GLUtils, GLExtrusion,
  GLGeomObjects, GLSpaceText, GLColor,
  GLzBuffer, GLMultiPolygon, GLGui, GLWindows,
  GLSmoothNavigator, GLFPSMovement, GLNavigator;

type
  TForm4 = class(TForm)
    GLSceneViewer1: TGLSceneViewer;
    GLScene1: TGLScene;
    GLCubeTable: TGLCube;
    GLLightSource1: TGLLightSource;
    GLCamera1: TGLCamera;
    GLExtrusionSolid1: TGLExtrusionSolid;
    GLArrowLineZ: TGLArrowLine;
    GLArrowLineY: TGLArrowLine;
    GLArrowLineX: TGLArrowLine;
    GLSpaceText1: TGLSpaceText;
    GLXYZGridTable: TGLXYZGrid;
    GLDummyCubeCenter: TGLDummyCube;
    GLDummyCube2: TGLDummyCube;
    GLCylinderToolshaft: TGLCylinder;
    GLAnnulus1: TGLAnnulus;
    Timer1: TTimer;
    GLLinesPath: TGLLines;
    Timer2: TTimer;
    GLXYZGridWP: TGLXYZGrid;
    GLLinesToolProjection: TGLLines;
    GLHeightFieldWP: TGLHeightField;
    CheckWorkGrid: TCheckBox;
    Panel1: TPanel;
    CheckToolpathVisible: TCheckBox;
    ComboBoxRes: TComboBox;
    GLSphereTooltip: TGLSphere;
    GLDummyCubeTool: TGLDummyCube;
    GLCylinderTooltip: TGLCylinder;
    ComboBoxSimType: TComboBox;
    GLCubeWP: TGLCube;
    PanelLED: TPanel;
    GLXYZGridWP10: TGLXYZGrid;
    GLSpaceTextX: TGLSpaceText;
    GLSpaceTextX50: TGLSpaceText;
    GLSpaceTextX100: TGLSpaceText;
    GLSpaceTextY: TGLSpaceText;
    GLSpaceTextY50: TGLSpaceText;
    GLSpaceTextY100: TGLSpaceText;
    GLSpaceTextX150: TGLSpaceText;
    GLSpaceTextX200: TGLSpaceText;
    GLSpaceTextY150: TGLSpaceText;
    GLSpaceTextY200: TGLSpaceText;
    GLSpaceTextX250: TGLSpaceText;
    GLSpaceTextY250: TGLSpaceText;
    GLDummyCubeTarget: TGLDummyCube;
    GLCadencer1: TGLCadencer;
    GLSphere2: TGLSphere;
    GLLineNeedle: TGLLines;
    GLSpaceTextToolZ: TGLSpaceText;
    GLLinesCallout: TGLLines;
    CheckLiveRender: TCheckBox;
    GLSmoothNavigator1: TGLSmoothNavigator;
    GLSmoothUserInterface1: TGLSmoothUserInterface;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure GLSceneViewer1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GLSceneViewer1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormRefresh(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormReset;
    procedure Timer2Timer(Sender: TObject);
    procedure GLHeightFieldWPGetHeight(const x, y: Single; var z: Single;
      var Color: TVector4f; var TexPoint: TTexPoint);
    procedure CheckWorkGridClick(Sender: TObject);
    procedure CheckToolpathVisibleClick(Sender: TObject);
    procedure ComboBoxSimTypeChange(Sender: TObject);
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure PanelLEDClick(Sender: TObject);

  private
    { Private-Deklarationen }
    { Private declarations }
    //UI:  TGLSmoothUserInterface;
    //Navigator: TGLSmoothNavigator;
    //  RealPos: TPoint;

  public
    { Public-Deklarationen }
  end;

  TLed = class
    private
      IsOn: Boolean;
      procedure SetLED(led_on: Boolean);
    public
      property Checked: Boolean read IsOn write SetLED;
    end;

procedure SetSimToolMM(d: Double; tooltip: integer; tool_color: TColor);
procedure Finalize3Dview;
// XYZ-Position Werkzeugspitze relativ zur 0,0 von Werkst�ckoberfl�che in mm
procedure SetSimPositionMMxyz(x, y, z:Double);
procedure SetSimPositionMMxy(x, y:Double);
procedure SimMillAtPos(x, y, z, dia: Double; new_vec, show_tool: boolean);
procedure SetSimPosColorMM(x, y, z:Double; tool_color: TColor);
procedure MakeToolArray(dia: Double);


var
  ShiftState: TShiftState;
  mouseDownX, mouseDownY: Integer;
  mouseMovedX, mouseMovedY: Integer;

  LEDbusy3d: TLed;
  Form4: TForm4;
  sim_x, sim_y, sim_z, sim_dia: Double;
  sim_seek, sim_z_abovezero, sim_render_finel: Boolean;
  sim_tooltip: Integer;
  sim_color: TColor;
  sim_feed: Integer;
  ena_solid, ena_finite: Boolean;
  toolpath_array: Array of TIntPoint;
  draw_tool_sema, render_sema: Boolean;
  mill_array: Array of Array of Double; // XY-Array mit H�henwerten
  mill_array_sizeX, mill_array_sizeY: Integer;
  tool_array: Array of Array of Double; // XY-Array mit H�henwerten
  tool_array_size: integer;
  tool_mid: Double;
  tool_mid_int: Integer;
  tool_running: Boolean;   // f�r Animation Drehung
  sim_active: Boolean;
  tool_rpm: Integer;
  gl_arr_scale, gl_bresenham_scale: Integer;   // Teilung XY-Array f�r Simulation
  gl_mult_scale: Double;

const
  c_GLscale = 10.0;    // Faktor f�r GLscene

implementation

uses grbl_player_main, grbl_com;

{$R *.dfm}

procedure TLed.SetLED(led_on: boolean);
// liefert vorherigen Zustand zur�ck
begin
  if led_on then begin
    Form4.PanelLED.Color:= clred;
    Form4.PanelLED.Font.Color:= clWhite;
  end else begin
    Form4.PanelLED.Color:= clmaroon;
    Form4.PanelLED.Font.Color:= clgray;
  end;
  IsOn:= led_on;
  Application.ProcessMessages;
end;


procedure SetToolPosition(glx, gly, glz:Double; tool_color: TColor);   //Werkzeugspitze
// XYZ-Position Werkzeugspitze relativ zur 0,0 von Werkst�ckoberfl�che auf GL skaliert
begin
  with Form4 do begin
    GLDummyCubeTool.Position.X:= glx;
    GLDummyCubeTool.Position.Y:= gly;
    GLDummyCubeTool.Position.Z:= glz;
    if (glz <= 0)then begin
      GLCylinderToolshaft.Material.FrontProperties.Emission.AsWinColor:= tool_color;
      GLCylinderTooltip.Material.FrontProperties.Emission.AsWinColor:= tool_color;
      GLSphereTooltip.Material.FrontProperties.Emission.AsWinColor:= tool_color;
    end else begin
      GLCylinderToolshaft.Material.FrontProperties.Emission.Color:= clrblack;
      GLCylinderTooltip.Material.FrontProperties.Emission.Color:= clrblack;
      GLSphereTooltip.Material.FrontProperties.Emission.Color:= clrblack;
    end;
  end;
end;

procedure SetSimPosColorMM(x, y, z:Double; tool_color: TColor);
// XYZ-Position Werkzeugspitze relativ zur 0,0 von Werkst�ckoberfl�che in mm
begin
  if not Form1.Show3DPreview1.Checked then
    exit;
  SetToolPosition(x/c_GLscale, y/c_GLscale, z/c_GLscale, tool_color)
end;

procedure SetSimPositionMMxy(x, y:Double);
// XYZ-Position Werkzeugspitze relativ zur 0,0 von Werkst�ckoberfl�che in mm
begin
  if not Form1.Show3DPreview1.Checked then
    exit;
  sim_x:= x; sim_y:= y;
  SetToolPosition(x/c_GLscale, y/c_GLscale, sim_z/c_GLscale, clblack);
  Form4.GLLinesPath.Nodes.Clear;
end;

procedure SetSimPositionMMxyz(x, y, z:Double);
// XYZ-Position Werkzeugspitze relativ zur 0,0 von Werkst�ckoberfl�che in mm
begin
  if not Form1.Show3DPreview1.Checked then
    exit;
  sim_x:= x; sim_y:= y; sim_z:= z;
  SetToolPosition(x/c_GLscale, y/c_GLscale, sim_z/c_GLscale, clblack);
  Form4.GLSpaceTextToolZ.Text:= FormatFloat('00.0 mm', sim_z);
  Form4.GLLinesPath.Nodes.Clear;
end;

procedure SetTool(glr: Double; tooltip: integer; tool_color: TColor);
// Werkzeugdurchmesser und -spitze setzen, auf GL skalierte Werte
begin
  if not Form1.Show3DPreview1.Checked then
    exit;
  with Form4 do begin
    GLCylinderToolshaft.TopRadius:= glr;
    GLCylinderToolshaft.BottomRadius:= glr;
    GLCylinderTooltip.TopRadius:= glr;
    GLSphereTooltip.Position.Z:= glr;
    GLSphereTooltip.Radius:= glr;
    case tooltip of
      0: // Flat tip
        begin
          GLSphereTooltip.visible:= false;
          GLCylinderTooltip.visible:= true;
          GLCylinderTooltip.BottomRadius:= glr;
          GLCylinderTooltip.Height:= glr*2;
        end;
      1: // Cone 30�
        begin
          GLSphereTooltip.visible:= false;
          GLCylinderTooltip.visible:= true;
          GLCylinderTooltip.BottomRadius:= 0;
          GLCylinderTooltip.Height:= glr*3;

        end;
      2: // Cone 45�
        begin
          GLSphereTooltip.visible:= false;
          GLCylinderTooltip.visible:= true;
          GLCylinderTooltip.BottomRadius:= 0;
          GLCylinderTooltip.Height:= glr*2;

        end;
      3: // Cone 60�
        begin
          GLSphereTooltip.visible:= false;
          GLCylinderTooltip.visible:= true;
          GLCylinderTooltip.BottomRadius:= 0;
          GLCylinderTooltip.Height:= glr*1.5;

        end;
      4: // Cone 90�
        begin
          GLSphereTooltip.visible:= false;
          GLCylinderTooltip.visible:= true;
          GLCylinderTooltip.BottomRadius:= 0;
          GLCylinderTooltip.Height:= glr;
        end;
      5: // Ball
        begin
          GLSphereTooltip.visible:= true;
          GLCylinderTooltip.visible:= false;
          GLCylinderTooltip.Height:= glr;
        end;
    end;
    GLCylinderTooltip.Position.Z:= GLCylinderTooltip.Height / 2;
    GLCylinderToolshaft.Height:= 2-GLCylinderTooltip.Height;
    GLCylinderToolshaft.Position.Z:= GLCylinderTooltip.Height + GLCylinderToolshaft.Height/2;
    GLSphereTooltip.Material.FrontProperties.Diffuse.Color:= GLCylinderToolshaft.Material.FrontProperties.Diffuse.Color;
    GLSphereTooltip.Material.BackProperties.Diffuse.Color:= GLCylinderToolshaft.Material.BackProperties.Diffuse.Color;
    GLSphereTooltip.Material.FrontProperties.Ambient.Color:= GLCylinderToolshaft.Material.FrontProperties.Ambient.Color;
    GLSphereTooltip.Material.BackProperties.Ambient.Color:= GLCylinderToolshaft.Material.BackProperties.Ambient.Color;
    GLCylinderTooltip.Material.FrontProperties.Diffuse.Color:= GLCylinderToolshaft.Material.FrontProperties.Diffuse.Color;
    GLCylinderTooltip.Material.BackProperties.Diffuse.Color:= GLCylinderToolshaft.Material.BackProperties.Diffuse.Color;
    GLCylinderTooltip.Material.FrontProperties.Ambient.Color:= GLCylinderToolshaft.Material.FrontProperties.Ambient.Color;
    GLCylinderTooltip.Material.BackProperties.Ambient.Color:= GLCylinderToolshaft.Material.BackProperties.Ambient.Color;
  end;
end;

procedure SetSimToolMM(d: Double; tooltip: integer; tool_color: TColor);
// Werkzeugdurchmesser und -spitze setzen, Werte in Millimetern
begin
  if not Form1.Show3DPreview1.Checked then
    exit;
  sim_dia:= d;
  sim_tooltip:= tooltip;
  sim_color:= tool_color;
  SetTool(d/2/c_GLscale, tooltip, tool_color);
end;

procedure Finalize3Dview;
// letzte Aktualisierung
begin
  render_sema:= ena_finite;
  LEDbusy3d.Checked:= render_sema;
end;


// #############################################################################
// ############################ M I L L  A R R A Y #############################
// #############################################################################

procedure MillArrayWithTool(x, y, z: Double);
// Tool-Array mit Werkzeugform an Position XY des mill_array anwenden
var
  ix, iy: Integer;
  sz, old_z, new_z, height: Double;
  ax, ay, px, py: Integer;
begin
  if not Form1.Show3DPreview1.Checked then
    exit;
  if z > 0 then  // H�he �ber Werkst�ck
    exit;
  sz:= z / c_GLscale;
  ax:= round(x * gl_arr_scale);
  ay:= round(y * gl_arr_scale);
   // Werkzeug-Array anwenden
  for ix:= 0 to tool_array_size-1 do
    for iy:= 0 to tool_array_size-1 do begin
      px:= ax + ix;
      py:= ay + iy;
      if (px <= mill_array_sizeX) and (py <= mill_array_sizeY)
      and (px >= tool_mid_int) and (py >= tool_mid_int) then begin
      // wir sind innerhalb des Tool-Rechecks
        old_z:= mill_array[px - tool_mid_int, py - tool_mid_int]; // ungefr�st = 0
        new_z:= sz + tool_array[ix,iy]; // in der Mitte Null, am Rand +10 zzgl. z
        if (new_z < old_z) then
          // es wurde etwas weggefr�st
          mill_array[px - tool_mid_int, py - tool_mid_int]:= new_z;
      end;
    end;
end;



procedure MakeToolArray(dia: Double);
// Werkzeug f�r 3D-Sim erstellen, Grundform ist ein Kreis in einem quadratischen Array
// Werkkeugspitze ist Null, au�erhalb Werkzeug +10
var
  ix, iy: Integer;
  vz, h, r: Double;  // L�nge vom Kreismittelpunkt, Tool-Radius-Faktor
begin
  tool_array_size:= round(dia * gl_arr_scale);
  r:= dia/2;
  tool_mid:= round(r * gl_arr_scale);
  tool_mid_int:= round(tool_mid);
  setlength(tool_array, tool_array_size);
  for ix:= 0 to tool_array_size-1 do begin
    setlength(tool_array[ix], tool_array_size);
  end;
  for ix:= 0 to tool_array_size-1 do
    for iy:= 0 to tool_array_size-1 do begin
      vz:=sqrt(sqr(ix-tool_mid) + sqr(iy-tool_mid));
      if (vz <= tool_mid) then begin // im gew�nschten Radius?
        // wir sind innerhalb der Kreisfl�che. Jetzt Spitze bestimmen
        h:= 10; // default au�erhalb
        case sim_tooltip of
          0: // Flat tip
            h:= 0;   // neue Fr�stiefe an diesem Punkt des Werkzeugs
          1: // Cone 30�
            h:= vz*3 / gl_arr_scale ;
          2: // Cone 45�
            h:= vz*2 / gl_arr_scale ;
          3: // Cone 60�
            h:= vz*1.5 / gl_arr_scale ;
          4: // Cone 90�
            h:= vz / gl_arr_scale ;
          5: // Ball
            h:= (tool_mid - sqrt(sqr(tool_mid) - sqr(vz))) / gl_arr_scale;
        end;
        tool_array[ix,iy]:= h / c_GLscale   // neue Fr�stiefe, positiv = im Werkst�ck
      end else
        tool_array[ix,iy]:= 10;  // weit au�erhalb Werkst�ck
    end;
end;

// #############################################################################
// #############################################################################
// #############################################################################

procedure SimMillAtPos(x, y, z, dia: Double; new_vec, show_tool: boolean);
var
  last_node: Integer;
  sx, sy, sz: Double; // auf GL skalierte Werte
begin
  if not Form1.Show3DPreview1.Checked then
    exit;

  Form4.GLLinesPath.Visible:= show_tool and Form4.CheckToolpathVisible.Checked;
  Form4.GLDummyCubeTool.visible:= show_tool;

  sx:= x / c_GLscale;
  sy:= y / c_GLscale;
  sz:= z / c_GLscale;
  // sdia:= dia / c_GLscale;
  with Form4 do begin
    last_node:= GLLinesPath.Nodes.Count-1;
    if (last_node < 1) or new_vec then begin
      GLLinesPath.Nodes.AddNode(sx,sy,sz+0.02);
      last_node:= GLLinesPath.Nodes.Count-1;
    end else begin
      TGLLinesNode(GLLinesPath.Nodes[last_node]).x:=sx;
      TGLLinesNode(GLLinesPath.Nodes[last_node]).y:=sy;
      TGLLinesNode(GLLinesPath.Nodes[last_node]).z:=sz+0.02;
    end;

    if (z <= 0) then begin
      if sim_z_abovezero then begin
        GLLinesPath.Nodes.AddNode(sx,sy,sz+0.02);
        last_node:= GLLinesPath.Nodes.Count-1;
      end;
      TGLLinesNode(GLLinesPath.Nodes[last_node]).Color.AsWinColor:= sim_color;
      sim_z_abovezero:= false;
      if ena_finite then
        MillArrayWithTool(x,y,z);
      render_sema:= CheckLiveRender.checked and (Form1.TrackbarSimSpeed.Position < 10);
    end else begin
      if not sim_z_abovezero then begin
        GLLinesPath.Nodes.AddNode(sx,sy,sz+0.02);
        last_node:= GLLinesPath.Nodes.Count-1;
      end;
      TGLLinesNode(GLLinesPath.Nodes[last_node]).Color.color:= clrSeaGreen;
      sim_z_abovezero:= true;
    end;
  end;
  if show_tool and (draw_tool_sema or new_vec) then //
    SetToolPosition(sx,sy,sz, sim_color);
  draw_tool_sema:= false;
end;


// #############################################################################
// User interface - Form
// #############################################################################

procedure TForm4.GLHeightFieldWPGetHeight(const x, y: Single; var z: Single;
  var Color: TVector4f; var TexPoint: TTexPoint);
// Callback von Heightfield, gibt aktuelle H�he der Zelle zur�ck

var ax, ay: Integer;
begin
  ax:= round(x * gl_mult_scale);
  ay:= round(y * gl_mult_scale);
  z:= mill_array[ax,ay];
end;

procedure TForm4.FormCreate(Sender: TObject);
var
  grbl_ini:TRegistry;
begin
  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr, true);
    if grbl_ini.ValueExists('SceneFormTop') then
      Top:= grbl_ini.ReadInteger('SceneFormTop');
    if grbl_ini.ValueExists('SceneFormLeft') then
      Left:= grbl_ini.ReadInteger('SceneFormLeft');
  finally
    grbl_ini.Free;
  end;
  LEDbusy3D:= Tled.Create;
  gl_arr_scale:= 1;   // Teilung XY-Array f�r Simulation, grob
  gl_bresenham_scale:= 5;
end;

procedure TForm4.FormClose(Sender: TObject; var Action: TCloseAction);
var
  grbl_ini:TRegistry;
begin
  grbl_ini:= TRegistry.Create;
  try
    grbl_ini.RootKey := HKEY_CURRENT_USER;
    grbl_ini.OpenKey('SOFTWARE\Make\GRBlize\'+c_VerStr, true);
    grbl_ini.WriteInteger('SceneFormTop',Top);
    grbl_ini.WriteInteger('SceneFormLeft',Left);
//    grbl_ini.WriteInteger('SceneFormWidth',Width);
//    grbl_ini.WriteInteger('SceneFormHeight',Height);
  finally
    grbl_ini.Free;
  end;
  Form1.WindowMenu1.Items[2].Checked:= false;
  //GLCadencer1.Enabled:= false;
end;

procedure TForm4.FormReset;

begin
  GLsceneViewer1.Invalidate;
  GLSmoothNavigator1.VirtualUp.AsAffineVector:= YVector;
  GLSmoothNavigator1.AutoScaleParameters(100);  // Startwert
  GLXYZgridWP.Visible:= CheckWorkGrid.Checked;

  sim_color:= clLime;
  sim_seek:= false;
  SetSimToolMM(sim_dia,sim_tooltip, clgray);
  SetSimPosColorMM(sim_x, sim_y,sim_z, clgray);

  //GLDummyCube3.DeleteChildren;
  GLLinesPath.Nodes.Clear;
  GLArrowLineZ.Position.Z:= job.partsize_z / c_GLscale;
  GLArrowLineZ.Position.X:= -job.partsize_x / (c_GLscale*2);
  GLArrowLineZ.Position.Y:= -job.partsize_y / (c_GLscale*2);

  // Tisch ist zentriert in Bildmitte
  GLCubeTable.CubeWidth:= job.partsize_x / c_GLscale + 2;
  GLCubeTable.CubeHeight:= job.partsize_y / c_GLscale + 2;

  // Gitter auf dem Tisch
  GLXYZgridTable.Position.X:= -job.partsize_x / (c_GLscale*2) -1;
  GLXYZgridTable.Position.Y:= -job.partsize_y / (c_GLscale*2) -1;
  GLXYZgridTable.Position.Z:= 0.01;
  GLXYZgridTable.XSamplingScale.Max:= job.partsize_x / c_GLscale + 2;
  GLXYZgridTable.YSamplingScale.Max:= job.partsize_y / c_GLscale + 2;

  // Gitter auf dem Werkst�ck, relativ zu Pfeilen
  GLXYZgridWP.Position.X:= 0;
  GLXYZgridWP.Position.Y:= 0;
  GLXYZgridWP.Position.Z:= 0.01;
  GLXYZgridWP.XSamplingScale.Max:= job.partsize_x / c_GLscale;
  GLXYZgridWP.YSamplingScale.Max:= job.partsize_y / c_GLscale;

  GLXYZgridWP10.XSamplingScale.Max:= job.partsize_x / c_GLscale;
  GLXYZgridWP10.YSamplingScale.Max:= job.partsize_y / c_GLscale;

  GLSpaceTextX50.visible:= job.partsize_x >= 50;
  GLSpaceTextX100.visible:= job.partsize_x >= 100;
  GLSpaceTextX150.visible:= job.partsize_x >= 150;
  GLSpaceTextX200.visible:= job.partsize_x >= 200;
  GLSpaceTextX250.visible:= job.partsize_x >= 250;

  GLSpaceTextY50.visible:= job.partsize_y >= 50;
  GLSpaceTextY100.visible:= job.partsize_y >= 100;
  GLSpaceTextY150.visible:= job.partsize_y >= 150;
  GLSpaceTextY200.visible:= job.partsize_y >= 200;
  GLSpaceTextY250.visible:= job.partsize_y >= 250;

  GLSpaceText1.Position.Y:= -job.partsize_y / (c_GLscale*2) -1.05;

  // Umrandung f�r
  GLCubeWP.CubeWidth:= job.partsize_x / c_GLscale;
  GLCubeWP.CubeDepth:= job.partsize_y / c_GLscale;
  GLCubeWP.CubeHeight:= job.partsize_z / c_GLscale;
  GLCubeWP.Position.X:= 0; // Mitte
  GLCubeWP.Position.Y:= 0;
  GLCubeWP.Position.Z:= job.partsize_z / (c_GLscale*2);
  GLDummyCubeTarget.Position.Z:= job.partsize_z / c_GLscale; // Stecknadel

  with GLExtrusionSolid1, Contours do begin
    DeleteChildren;
    Height:= job.partsize_z / c_GLscale;
    Position.X:= -job.partsize_x / (c_GLscale*2);
    Position.Y:= -job.partsize_y / (c_GLscale*2);
    Clear;

    // Werkst�ck erstellen
    with Add.Nodes do begin
      AddNode(0, 0, 0);
      AddNode(job.partsize_x / c_GLscale, 0, 0);
      AddNode(job.partsize_x / c_GLscale, job.partsize_y / c_GLscale, 0);
      AddNode(0, job.partsize_y / c_GLscale, 0);
    end;
    Add;
  end;
  gl_mult_scale:= c_GLscale * gl_arr_scale;
  GLHeightFieldWP.XSamplingScale.Step:= 1/gl_mult_scale;
  GLHeightFieldWP.YSamplingScale.Step:= 1/gl_mult_scale;
end;

procedure TForm4.FormRefresh(Sender: TObject);
// Display number of triangles used in the mesh
// You will note that this number quickly gets out of hand if you are
// using large high-resolution grids
var
  i, j, m, p, my_len, my_pen, ix, iy : Integer;
  x, y, z: Single;
  my_entry: Tfinal;
  my_Polygon: TGLPolygon;
  my_disk: TGLDisk;
  my_hole: TGLAnnulus;
  my_offset: TIntPoint;
  my_radius, my_dia: Double;
  my_mill_color_corr: Single;
  outer_paths, inner_paths: Tpaths;
  my_poly_end: TEndType;
  my_mill_colorvec: TColorVector;
  my_mill_color: TColor;
  my_hpgl_div: Double;
  ZeroOfs: TIntpoint;

begin
  ComboBoxSimTypeChange(Sender);
  FormReset;
  my_hpgl_div:= c_hpgl_scale * c_GLscale;
  if ena_solid then with GLExtrusionSolid1, Contours do begin
    // Werkst�ck Outlines/Umrisse einsetzen; k�nnen auch mehrere sein
    for i:= 0 to length(final_array)-1 do begin
      my_entry:= final_array[i];
      if not my_entry.enable then
        continue;
      z:= -job.pens[my_entry.pen].z_end;
      if z >= 0 then
        continue;
      my_offset:= job.pens[my_entry.pen].offset;
      my_dia:= job.pens[my_entry.pen].diameter;

      if my_entry.shape = drillhole then begin
        if length(my_entry.millings[0]) > 0 then
          for p:= 0 to length(my_entry.millings[0])-1 do begin // Anzahl Pfade
            my_hole:= TGLannulus(GLExtrusionSolid1.AddNewChild(TGLannulus)); // Bohrloch erstellen
            my_hole.PitchAngle:= 90;
            my_hole.position.x:= int(my_entry.millings[0, p].x + my_offset.x) / my_hpgl_div;
            my_hole.position.y:= int(my_entry.millings[0, p].y + my_offset.y) / my_hpgl_div;
            my_hole.height:= job.partsize_z / c_GLscale + 0.02;
            my_hole.position.z:= my_hole.height / 2;
            my_hole.TopinnerRadius:= my_dia / (c_GLscale*2);

            my_hole.TopRadius:= my_hole.TopinnerRadius * 1.2;
            my_hole.BottominnerRadius:= my_hole.TopinnerRadius;
            my_hole.BottomRadius:= my_hole.TopRadius;
            my_hole.Material.FrontProperties.Emission.Color:= clrBlack;
            my_hole.Material.FrontProperties.Ambient.Color:= clrGray50;
            my_hole.Material.FrontProperties.Diffuse.Color:= clrGray25;

            my_disk:= TGLdisk(GLExtrusionSolid1.AddNewChild(TGLdisk)); // Bohrlochmitte erstellen
            my_disk.PitchAngle:= 0;
            my_disk.position.x:= my_hole.position.x;
            my_disk.position.y:= my_hole.position.y;
            my_disk.position.z:= my_hole.height - 0.01;
            my_disk.OuterRadius:= my_hole.TopinnerRadius;
            my_disk.Material.FrontProperties.Emission.Color:= clrBlack;
            my_disk.Material.FrontProperties.Ambient.Color:= clrGray25;
            my_disk.Material.FrontProperties.Diffuse.Color:= clrGray15;
          end;
        continue;
      end;

      my_radius:= my_dia * (c_hpgl_scale div 2);  // = mm * 40plu / 2 in HPGL-Units
      if z < 0 then
        my_mill_color_corr:=  1 - 0.4 * (1+abs(z))/(1+my_dia*2) // je tiefer und enger, desto duster
      else
        my_mill_color_corr:= 1.0;
      if my_mill_color_corr < 0.1 then
        my_mill_color_corr:= 0.1;
      my_mill_colorvec:= GLExtrusionSolid1.Material.FrontProperties.Diffuse.Color;
      my_mill_color:= ConvertColorVector(my_mill_colorvec, my_mill_color_corr);
      my_mill_colorvec:= ConvertWinColor(my_mill_color, 1);
      z:= (z / c_GLscale) + (job.partsize_z / c_GLscale);  // Skalierung

      with TClipperOffset.Create() do
        try
          Clear;
          ArcTolerance:= round(my_radius) div (c_hpgl_scale div 2) + 1;
          if my_entry.closed then
            my_poly_end:= etClosedPolygon
          else
            my_poly_end:= etOpenRound;
          AddPaths(my_entry.millings, jtRound, my_poly_end);
          Execute(outer_paths, my_radius);
          Execute(inner_paths, -my_radius);
        finally
          Free;
        end;

        if my_entry.shape <> pocket then
          for j:= 0 to length(inner_paths)-1 do
            inner_paths[j]:= ReversePath(inner_paths[j]);

        if length(outer_paths) > 0 then
          for m:= 0 to length(outer_paths)-1 do  // Anzahl Pfade
            if length(outer_paths[m]) > 0 then with Add.Nodes do begin
              if m = 0 then begin
                my_Polygon:= TGLPolygon(GLExtrusionSolid1.AddNewChild(TGLPolygon));
                my_Polygon.Position.Z:= z;  // z inkl. Werkst�ck
                my_Polygon.Material.FrontProperties.Emission.Color:= clrBlack;
                my_Polygon.Material.FrontProperties.Ambient.Color:= my_mill_colorvec;
                my_Polygon.Material.FrontProperties.Diffuse.Color:= my_mill_colorvec;
              end;
              for p:= 0 to length(outer_paths[m])-1 do begin
                x:= int(outer_paths[m,p].x + my_offset.x) / my_hpgl_div;
                y:= int(outer_paths[m,p].y + my_offset.y) / my_hpgl_div;
                AddNode(x, y, 0);
                if m = 0 then
                  // Polygon f�r Werkst�ck in Fr�stiefe erstellen, au�en
                  my_Polygon.AddNode(x, y, 0);
              end;
            end;

        if my_entry.shape <> pocket then begin
          Add; // Leere Kontur
          if length(inner_paths) > 0 then
            for m:= 0 to length(inner_paths)-1 do  // Anzahl Pfade
              if length(inner_paths[m]) > 0 then with Add.Nodes do begin
                for p:= 0 to length(inner_paths[m])-1 do begin
                  x:= int(inner_paths[m,p].x + my_offset.x) / my_hpgl_div;
                  y:= int(inner_paths[m,p].y + my_offset.y) / my_hpgl_div;
                  AddNode(x, y, 0);
                end;
              end;
          end;
        end;
  end; // ena_solid
  GLHeightFieldWP.Position.Z:= 0;
  GLHeightFieldWP.XSamplingScale.Max:= job.partsize_x / c_GLscale;
  GLHeightFieldWP.YSamplingScale.Max:= job.partsize_y / c_GLscale;

  // Mill-Array erzeugen. Zweidimensionales Array mit Z-Werten f�r jeden Teilpunkt
  j:= round(job.partsize_x * gl_arr_scale);
  m:= round(job.partsize_y * gl_arr_scale);
  inc(j);
  inc(m);
  mill_array_sizeX:= j;
  mill_array_sizeY:= m;
  setlength(mill_array, j);
  for i:= 0 to j-1 do begin
    setlength(mill_array[i], m);
    for p:= 0 to m-1 do
      mill_array[i,p]:= 0.0;
  end;
end;

// #############################################################################
// User interface - Panel
// #############################################################################

procedure TForm4.CheckWorkGridClick(Sender: TObject);
begin
  GLsceneViewer1.Invalidate;
  GLSpaceTextToolZ.Visible:= CheckWorkGrid.Checked;
  GLLinesCallout.Visible:= CheckWorkGrid.Checked;
  GLXYZgridWP.Visible:= CheckWorkGrid.Checked;
end;

procedure TForm4.ComboBoxSimTypeChange(Sender: TObject);
begin
  case ComboBoxSimType.ItemIndex of
    0:
    begin
      ena_solid:= false;
      ena_finite:= false;
      CheckLiveRender.Checked:= false;
      CheckLiveRender.Enabled:= false;
      gl_arr_scale:= 1;   // Teilung XY-Array f�r Simulation
      gl_bresenham_scale:= 5;
    end;
    1:
    begin
      ena_solid:= true;
      ena_finite:= false;
      CheckLiveRender.Checked:= false;
      CheckLiveRender.Enabled:= false;
      gl_arr_scale:= 1;   // Teilung XY-Array f�r Simulation
      gl_bresenham_scale:= 5;
    end;
    2:
    begin
      ena_solid:= false;
      ena_finite:= true;
      CheckLiveRender.Enabled:= true;
      case ComboBoxRes.ItemIndex of
        0:
          gl_arr_scale:= 2;   // Teilung XY-Array f�r Simulation
        1:
          gl_arr_scale:= 5;   // Teilung XY-Array f�r Simulation
        2:
          gl_arr_scale:= 10;  // Teilung XY-Array f�r Simulation
      end;
      gl_bresenham_scale:= gl_arr_scale;
    end;
  end;
  GLHeightFieldWP.Visible:= ena_finite;
  GLCubeWP.Visible:= ena_finite;
  GLExtrusionSolid1.visible:= ena_solid;
  ComboBoxRes.Enabled:= ena_finite;
  GLsceneViewer1.Invalidate;
  GLSmoothNavigator1.AutoScaleParameters(100);
end;


procedure TForm4.CheckToolpathVisibleClick(Sender: TObject);
begin
  GLLinesPath.Visible:= CheckToolpathVisible.Checked;
  GLsceneViewer1.Invalidate;
  GLSmoothNavigator1.AutoScaleParameters(100);
end;

// #############################################################################
// User interface - Maus
// #############################################################################

procedure TForm4.Timer1Timer(Sender: TObject);
// jede Sekunde
begin
  GLsceneViewer1.Invalidate;
  GLSmoothNavigator1.AutoScaleParameters(GLSceneViewer1.FramesPerSecond + 20);
  Form4.Caption:=Format('3D View - %.2f FPS', [GLSceneViewer1.FramesPerSecond]);
  if render_sema and ena_finite then begin
    LEDbusy3d.Checked:= true;
    GLHeightFieldWP.StructureChanged;
  end else
    LEDbusy3d.Checked:= false;
  render_sema:= false;
  GLSceneViewer1.ResetPerformanceMonitor;
  Form4.GLSpaceTextToolZ.Text:= 'Z ' + FormatFloat('0.0 mm', sim_z);
//  GLSceneViewer1.Invalidate;
end;

procedure TForm4.Timer2Timer(Sender: TObject);
// alle 50 ms
begin
  draw_tool_sema:= true;
  if sim_active then begin
    // wird bei laufendem Program sonst nicht aufgerufen
    GLCadencer1Progress(Sender, 50, 0);
  end;
  if tool_running then begin
    if tool_rpm < 60 then
      inc(tool_rpm);
    GLAnnulus1.Turn(tool_rpm);
  end else
    if tool_rpm > 0 then begin
      dec(tool_rpm);
      GLAnnulus1.Turn(tool_rpm);
    end;
end;

procedure TForm4.GLCadencer1Progress(Sender: TObject; const deltaTime, newTime: Double);
// sanfte Bewegung erm�glichen
var
  dx, dy: Integer;
begin
  dx:= mouseDownX - mouseMovedX;
  dy:= mouseDownY - mouseMovedY;

  if (ssLeft in ShiftState) and (ssRight in ShiftState) then begin
  // "Stecknadel" in der H�he verschieben
    if GLDummyCubeTarget.Position.Z > dy/20 then
      GLDummyCubeTarget.Position.Z:= GLDummyCubeTarget.Position.Z - (dy/20);
    GLSmoothNavigator1.MoveAroundTarget(0, 0, DeltaTime);
    GLSmoothNavigator1.AdjustDistanceToTarget(0, DeltaTime);
  end else if (ssRight in ShiftState) then begin
  // "Stecknadel" in XY-Richtung verschieben
    GLDummyCubeTarget.Position.Y:= GLDummyCubeTarget.Position.Y - (dy/20);
    GLDummyCubeTarget.Position.X:= GLDummyCubeTarget.Position.X + (dx/20);
    GLSmoothNavigator1.MoveAroundTarget(0, 0, DeltaTime);
    GLSmoothNavigator1.AdjustDistanceToTarget(0, DeltaTime);
  end else if (ssLeft in ShiftState) then begin
  // Arbeitsfl�che drehen
    GLSmoothNavigator1.MoveAroundTarget(dy, dx, DeltaTime);
    GLSmoothNavigator1.AdjustDistanceToTarget(0, DeltaTime);
  end else begin
  // auslaufende Bewegung
    GLSmoothNavigator1.AdjustDistanceToTarget(0, DeltaTime);
    GLSmoothNavigator1.MoveAroundTarget(0, 0, DeltaTime);
  end;

  mouseDownX := mouseMovedX;
  mouseDownY := mouseMovedY;
end;

procedure TForm4.GLSceneViewer1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ShiftState :=  Shift;
  mouseDownX := x;
  mouseDownY := y;
end;

procedure TForm4.GLSceneViewer1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  ShiftState :=  Shift;
  mouseMovedX := X;
  mouseMovedY := Y;
end;

procedure TForm4.PanelLEDClick(Sender: TObject);
begin
  GLDummyCubeTarget.Position.X:=  0;
  GLDummyCubeTarget.Position.Y:=  0;
  GLDummyCubeTarget.Position.Z:=  0;
  FormRefresh(Sender);
end;

procedure TForm4.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  // (WheelDelta / Abs(WheelDelta) is used to deternime the sign.
  GLSmoothNavigator1.AdjustDistanceParams.AddImpulse(( -WheelDelta * 2 / Abs(WheelDelta)));
  Handled:= true;
end;

end.
