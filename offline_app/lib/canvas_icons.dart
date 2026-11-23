import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// The icon set from the design canvas: 24-unit stroke paths, round caps, 1.9 stroke.
/// Paths use SVG path syntax so they match the canvas exactly.
const canvasIconPaths=<String,String>{
 'home':'M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z',
 'pie':'M12 3v9h9 M21 12a9 9 0 1 1-9-9',
 'jar':'M8 4h8v3H8z M7 7h10l1 3v9a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2v-9z M10 14h4',
 'receipt':'M6 3h12v18l-3-2-3 2-3-2-3 2z M9 8h6 M9 12h6 M9 16h3',
 'plus':'M12 5v14 M5 12h14',
 'gear':'M21.42 10.77 L21.42 13.23 L18.95 13.87 L18.24 15.59 L19.53 17.79 L17.79 19.53 L15.59 18.24 L13.87 18.95 L13.23 21.42 L10.77 21.42 L10.13 18.95 L8.41 18.24 L6.21 19.53 L4.47 17.79 L5.76 15.59 L5.05 13.87 L2.58 13.23 L2.58 10.77 L5.05 10.13 L5.76 8.41 L4.47 6.21 L6.21 4.47 L8.41 5.76 L10.13 5.05 L10.77 2.58 L13.23 2.58 L13.87 5.05 L15.59 5.76 L17.79 4.47 L19.53 6.21 L18.24 8.41 L18.95 10.13 Z M15 12a3 3 0 1 1-6 0a3 3 0 1 1 6 0',
 'chev':'M9 6l6 6-6 6',
 'back':'M15 6l-6 6 6 6',
 'close':'M6 6l12 12 M18 6 6 18',
 'search':'M17 11a6 6 0 1 1-12 0a6 6 0 1 1 12 0 M20 20l-4.5-4.5',
 'filter':'M4 6h16 M7 12h10 M10 18h4',
 'cal':'M4 6h16v14H4z M4 10h16 M8 3v4 M16 3v4',
 'wallet':'M3 7h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M3 7l12-4v4 M16 13.5h2',
 'cash':'M3 7h18v10H3z M15 12a3 3 0 1 1-6 0a3 3 0 1 1 6 0 M6 10v4 M18 10v4',
 'bank':'M3 10 12 4l9 6 M5 10v8 M9.5 10v8 M14.5 10v8 M19 10v8 M3 20h18',
 'swap':'M4 8h14l-3-3 M20 16H6l3 3',
 'repeat':'M4 11V9a3 3 0 0 1 3-3h12l-3-3 M20 13v2a3 3 0 0 1-3 3H5l3 3',
 'bell':'M6 16V11a6 6 0 0 1 12 0v5l2 2H4z M10 21h4',
 'lock':'M6 11h12v10H6z M8.5 11V8a3.5 3.5 0 0 1 7 0v3',
 'shield':'M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z M9 12l2 2 4-4',
 'upload':'M12 16V4 M7 9l5-5 5 5 M4 20h16',
 'download':'M12 4v12 M7 11l5 5 5-5 M4 20h16',
 'globe':'M21 12a9 9 0 1 1-18 0a9 9 0 1 1 18 0 M3 12h18 M12 3c3 3 3 15 0 18 M12 3c-3 3-3 15 0 18',
 'moon':'M20 14A8 8 0 1 1 10 4a6.5 6.5 0 0 0 10 10z',
 'bars':'M5 20V11 M12 20V5 M19 20v-7',
 'beach':'M3 12a9 9 0 0 1 18 0z M12 12v9 M8 21h8',
 'check':'M5 12l5 5 9-10',
 'edit':'M4 20h4L19 9l-4-4L4 16z M13 7l4 4',
 'trash':'M5 7h14 M9 7V4h6v3 M7 7l1 13h8l1-13',
 'cart':'M3 4h2l2 11h11l2-8H6 M9 20h.01 M17 20h.01',
 'bus':'M5 4h14v12H5z M5 11h14 M8 19v-3 M16 19v-3 M8 14h.01 M16 14h.01',
 'bolt':'M13 2 4 14h7l-1 8 9-12h-7z',
 'fork':'M7 3v8 M5 3v5a2 2 0 0 0 4 0V3 M7 11v10 M17 3c-2 0-3 3-3 6s1 4 3 4 M17 3v18',
 'heart':'M12 20s-8-4.5-8-10a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.5-8 10-8 10z',
 'bag':'M5 8h14l-1 13H6z M9 8V6a3 3 0 0 1 6 0v2',
 'phone':'M7 2h10v20H7z M11 18h2',
 'case':'M3 7h18v13H3z M9 7V4h6v3 M3 13h18',
 'crescent':'M15 4a8 8 0 1 0 5 13 7 7 0 0 1-5-13z M18 6v3 M16.5 7.5h3',
 'book':'M4 5h6a2 2 0 0 1 2 2v13a2 2 0 0 0-2-2H4z M20 5h-6a2 2 0 0 0-2 2v13a2 2 0 0 1 2-2h6z',
 'sun':'M16 12a4 4 0 1 1-8 0a4 4 0 1 1 8 0 M12 2v2 M12 20v2 M2 12h2 M20 12h2 M5 5l1.5 1.5 M17.5 17.5 19 19 M5 19l1.5-1.5 M17.5 6.5 19 5',
 'gift':'M4 10h16v4H4z M6 14h12v7H6z M12 10v11 M12 10c-2-4-6-4-6-1s6 1 6 1c0 0 6 2 6-1s-4-3-6 1',
 'car':'M4 16v-4l2-5h12l2 5v4z M4 16v3 M20 16v3 M7.5 13h.01 M16.5 13h.01',
 'finger':'M8 11a4 4 0 0 1 8 0v2 M5 14v-3a7 7 0 0 1 14 0v4 M12 11v5a4 4 0 0 0 2 3.5 M8.5 15c0 2 .5 4 2 5.5',
 'tag':'M3 12V4h8l10 10-8 8z M7.5 8.5h.01',
 'info':'M21 12a9 9 0 1 1-18 0a9 9 0 1 1 18 0 M12 11v6 M12 7.5h.01',
 'eye':'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z M15 12a3 3 0 1 1-6 0a3 3 0 1 1 6 0',
 'list':'M8 6h12 M8 12h12 M8 18h12 M4 6h.01 M4 12h.01 M4 18h.01',
 'dots':'M5 12h.01 M12 12h.01 M19 12h.01',
 'grid':'M4 4h7v7H4z M13 4h7v7h-7z M4 13h7v7H4z M13 13h7v7h-7z',
 'store':'M3 9l1.5-5h15L21 9 M3 9h18v2a3 3 0 0 1-6 0 3 3 0 0 1-6 0 3 3 0 0 1-6 0z M5 13v8h14v-8 M10 21v-5h4v5',
 'users':'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z M2 21v-1a6 6 0 0 1 12 0v1 M16 3.5a4 4 0 0 1 0 7.5 M22 21v-1a6 6 0 0 0-4-5.6',
 'cycle':'M21 12a9 9 0 0 1-15.5 6.2 M3 12A9 9 0 0 1 18.5 5.8 M18 2v4h-4 M6 22v-4h4',
 'star':'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z',
 'minus':'M5 12h14',
 'file':'M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z M14 3v5h5 M9 13h6 M9 17h6',
 'calc':'M6 2h12a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z M8 6h8v4H8z M8 14h.01 M12 14h.01 M16 14h.01 M8 18h.01 M12 18h.01 M16 18h.01',
 'paste':'M9 4h6v3H9z M8 5H6a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2 M8 12h8 M8 16h5',
 'split':'M16 3h5v5 M8 3H3v5 M21 3l-7.5 7.5 M3 3l7.5 7.5V21',
 'atm':'M3 5h18v6H3z M7 11v9h10v-9 M12 14v3 M10.5 15.5h3',
 'coins':'M9 8a6 3 0 1 0 0 .01 M3 8v4c0 1.7 2.7 3 6 3s6-1.3 6-3V8 M3 12v4c0 1.7 2.7 3 6 3 M15 11.5c3.3 0 6 1.3 6 3s-2.7 3-6 3-6-1.3-6-3 M21 14.5v4c0 1.7-2.7 3-6 3s-6-1.3-6-3',
 'grip':'M9 6h.01 M15 6h.01 M9 12h.01 M15 12h.01 M9 18h.01 M15 18h.01',
};

/// Minimal SVG path parser: M L H V C S A Z (absolute and relative).
Path parseCanvasPath(String d){
 final path=Path();
 final tokens=RegExp(r'[MmLlHhVvCcSsAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?').allMatches(d).map((m)=>m.group(0)!).toList();
 var i=0;var cmd='M';var x=0.0,y=0.0,sx=0.0,sy=0.0;double? cx2,cy2;
 bool isCmd(String t)=>RegExp(r'^[A-Za-z]$').hasMatch(t);
 double n()=>double.parse(tokens[i++]);
 while(i<tokens.length){
  if(isCmd(tokens[i])){cmd=tokens[i++];}
  final rel=cmd==cmd.toLowerCase();
  switch(cmd.toUpperCase()){
   case 'M':{
    final nx=n(),ny=n();x=rel?x+nx:nx;y=rel?y+ny:ny;sx=x;sy=y;path.moveTo(x,y);cx2=null;
    cmd=rel?'l':'L';break;}

   case 'L':{
    final nx=n(),ny=n();x=rel?x+nx:nx;y=rel?y+ny:ny;path.lineTo(x,y);cx2=null;break;}

   case 'H':{
    final nx=n();x=rel?x+nx:nx;path.lineTo(x,y);cx2=null;break;}

   case 'V':{
    final ny=n();y=rel?y+ny:ny;path.lineTo(x,y);cx2=null;break;}

   case 'C':{
    final a=n(),b=n(),c=n(),e=n(),f=n(),g=n();
    final x1=rel?x+a:a,y1=rel?y+b:b,x2=rel?x+c:c,y2=rel?y+e:e,x3=rel?x+f:f,y3=rel?y+g:g;
    path.cubicTo(x1,y1,x2,y2,x3,y3);cx2=x2;cy2=y2;x=x3;y=y3;break;}

   case 'S':{
    final c=n(),e=n(),f=n(),g=n();
    final x1=cx2==null?x:2*x-cx2,y1=cy2==null?y:2*y-cy2;
    final x2=rel?x+c:c,y2=rel?y+e:e,x3=rel?x+f:f,y3=rel?y+g:g;
    path.cubicTo(x1,y1,x2,y2,x3,y3);cx2=x2;cy2=y2;x=x3;y=y3;break;}

   case 'A':{
    final rx=n(),ry=n(),rot=n(),large=n()!=0,sweep=n()!=0,nx=n(),ny=n();
    x=rel?x+nx:nx;y=rel?y+ny:ny;
    path.arcToPoint(Offset(x,y),radius:Radius.elliptical(rx,ry),rotation:rot,largeArc:large,clockwise:sweep);cx2=null;break;}

   case 'Z':{
    path.close();x=sx;y=sy;cx2=null;break;}
   default:i++;
  }
 }
 return path;
}

final _cache=<String,Path>{};
Path canvasPath(String name)=>_cache.putIfAbsent(name,()=>parseCanvasPath(canvasIconPaths[name]!));

class CanvasGlyphPainter extends CustomPainter{
 const CanvasGlyphPainter(this.name,this.color,{this.mirror=false,this.stroke=1.9});
 final String name;final Color color;final bool mirror;final double stroke;
 @override void paint(Canvas c,Size size){
  c.save();c.scale(size.width/24,size.height/24);
  if(mirror){c.translate(24,0);c.scale(-1,1);}
  c.drawPath(canvasPath(name),Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=stroke
   ..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
  c.restore();
 }
 @override bool shouldRepaint(covariant CanvasGlyphPainter old)=>old.name!=name||old.color!=color||old.mirror!=mirror;
}

/// Canvas glyph for a category, from the same keyword matching as before.
String canvasGlyphForCategory(String glyph)=>switch(glyph){
 'housing'=>'home','utilities'=>'bolt','groceries'=>'cart','transport'=>'bus','health'=>'heart','family'=>'gift',
 'eating out'=>'fork','shopping'=>'bag','subscriptions'=>'phone','leisure'=>'sun','debt payment'=>'receipt',
 'income'||'salary'||'income plan'||'freelance'||'business'||'other income'=>'case','expense'=>'receipt',
 'reserve'=>'beach','savings'||'savings goal'=>'jar','gifts'=>'gift','education'=>'book','travel'=>'beach',
 'pets'=>'heart','daret'=>'cycle',_=>'tag',
};

/// Canvas glyph for an app icon, or null to keep the app's own drawing.
String? canvasGlyphForIcon(IconData icon){
 final m=<IconData,String>{
  Icons.space_dashboard_outlined:'home',Icons.space_dashboard:'home',Icons.pie_chart_outline:'pie',
  Icons.savings_outlined:'jar',Icons.savings:'jar',Icons.receipt_long_outlined:'receipt',Icons.receipt_long:'receipt',
  Icons.add:'plus',Icons.settings_outlined:'gear',Icons.chevron_right:'chev',Icons.chevron_left:'back',Icons.arrow_back:'back',
  Icons.close:'close',Icons.search:'search',Icons.tune:'filter',Icons.tune_outlined:'filter',
  Icons.calendar_today_outlined:'cal',Icons.today:'cal',Icons.event_outlined:'cal',Icons.edit_calendar_outlined:'cal',
  Icons.account_balance_wallet_outlined:'bank',Icons.payments_outlined:'cash',Icons.repeat:'swap',
  Icons.notifications_none:'bell',Icons.lock_outline:'lock',Icons.lock_open_outlined:'lock',Icons.ios_share:'upload',Icons.upload_outlined:'upload',
  Icons.file_open:'download',Icons.translate:'globe',Icons.dark_mode_outlined:'moon',Icons.light_mode_outlined:'sun',
  Icons.bar_chart_rounded:'bars',Icons.beach_access_outlined:'beach',Icons.check_circle_outline:'check',
  Icons.fact_check_outlined:'check',Icons.edit_outlined:'edit',Icons.info_outline:'info',Icons.visibility_outlined:'eye',
  Icons.visibility_off_outlined:'eye',Icons.grid_view:'grid',Icons.grid_view_outlined:'grid',Icons.trending_up:'bars',
  Icons.widgets_outlined:'eye',Icons.delete_outline:'trash',Icons.table_chart_outlined:'grid',
  Icons.bolt_outlined:'bolt',Icons.storefront_outlined:'store',Icons.directions_car_outlined:'car',Icons.people_outline:'users',
  Icons.check:'check',Icons.autorenew:'cycle',Icons.star_outline:'star',Icons.download_outlined:'download',Icons.remove:'minus',
  Icons.description_outlined:'file',Icons.calculate_outlined:'calc',Icons.content_paste:'paste',Icons.call_split:'split',
  Icons.local_atm_outlined:'atm',Icons.toll_outlined:'coins',Icons.handshake_outlined:'users',
  Icons.nightlight_outlined:'crescent',
 };
 return m[icon];
}

/// Rounded mint tile with a canvas glyph, as used at the start of rows on the canvas.
Color canvasTileColor(bool dark)=>dark?PaydayColors.darkIconDisc:PaydayColors.mintTint;
