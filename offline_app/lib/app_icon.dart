import 'canvas_icons.dart';
import 'design_tokens.dart';
import 'package:flutter/material.dart';
import 'localization.dart';
import 'category_icon.dart';

/// A single vector vocabulary for PAYDAY navigation, tools and controls.
/// Existing IconTheme colors preserve selected, disabled and warning states.
class PaydayAppIcon extends StatelessWidget {
 const PaydayAppIcon(this.icon,{super.key,this.size,this.color,this.semanticLabel,this.accent=false});
 final IconData icon;
 /// Saffron detail stroke. Off by default: saffron is reserved for the add button.
 final bool accent;
 final double? size;
 final Color? color;
 final String? semanticLabel;
 @override Widget build(BuildContext context){
  final theme=IconTheme.of(context);
  final dark=Theme.of(context).brightness==Brightness.dark;
  final extent=size??theme.size??24;
  final foreground=(color??theme.color??(dark?PaydayColors.darkIcon:PaydayColors.emerald)).withValues(alpha:theme.opacity??1);
  final widget=SizedBox.square(dimension:extent,child:CustomPaint(
   painter:_AppPainter(icon,foreground,dark,Directionality.of(context),accent)));
  return semanticLabel==null?ExcludeSemantics(child:widget):Semantics(label:semanticLabel==null?null:tr(context,semanticLabel!),child:widget);
 }
}
class _AppPainter extends CustomPainter{
 const _AppPainter(this.icon,this.color,this.dark,this.direction,this.withAccent);
 final bool withAccent;
 final IconData icon;
 final Color color;
 final bool dark;
 final TextDirection direction;
 @override void paint(Canvas c,Size size){
  // The design canvas icon set first; the app's own drawings only for icons it doesn't cover.
  final canvasName=canvasGlyphForIcon(icon);
  if(canvasName!=null){
   CanvasGlyphPainter(canvasName,color,mirror:direction==TextDirection.rtl&&const {'chev','back','swap'}.contains(canvasName)).paint(c,size);
   return;
  }
  String? glyph;
  if([Icons.savings,Icons.savings_outlined].contains(icon))glyph='savings';
  if(icon==Icons.beach_access_outlined)glyph='reserve';
  if(icon==Icons.payments_outlined)glyph='income plan';
  if(icon==Icons.call_received)glyph='income';
  if(icon==Icons.call_made)glyph='expense';
  if(glyph!=null){PaydayGlyphPainter(glyph,dark,foreground:color,accent:withAccent).paint(c,size);return;}
  c.save();c.scale(size.width/24,size.height/24);
  if(icon.matchTextDirection&&direction==TextDirection.rtl){c.translate(24,0);c.scale(-1,1);}
  final p=Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=1.7..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  final accent=Paint()..color=withAccent?PaydayColors.saffron.withValues(alpha:color.a):color
   ..style=PaintingStyle.stroke..strokeWidth=1.7..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  void l(double x,double y,double a,double b,[bool copper=false])=>c.drawLine(Offset(x,y),Offset(a,b),copper?accent:p);
  void circle(double x,double y,double r,[bool copper=false])=>c.drawCircle(Offset(x,y),r,copper?accent:p);
  void box(double x,double y,double w,double h,[bool copper=false])=>c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),Radius.circular(2)),copper?accent:p);
  void path(List<Offset> points,[bool copper=false]){
   final q=Path()..moveTo(points.first.dx,points.first.dy);
   for(final v in points.skip(1)){q.lineTo(v.dx,v.dy);}c.drawPath(q,copper?accent:p);
  }
  void dot(double x,double y)=>c.drawCircle(Offset(x,y),1,Paint()..color=accent.color);
  if(icon==Icons.translate){
   circle(12,12,8);c.drawOval(const Rect.fromLTWH(8,4,8,16),p);l(4,12,20,12);dot(17.5,6.5);
  }else if(icon==Icons.event_note_outlined){
   path([Offset(4,21),Offset(4,3),Offset(17,3),Offset(17,10)]);
   l(7,7,13,7);l(7,11,11,11);l(7,15,10,15);
   c.drawPath(Path()..moveTo(12,18)..lineTo(13,16)..lineTo(13,14)..cubicTo(13,10,19,10,19,14)..lineTo(19,16)..lineTo(20,18)..close(),accent);
   l(15,21,17,21,true);l(4,21,7,19);l(7,19,10,21);
  }else if(icon==Icons.schedule){
   circle(12,12,9);l(12,6,12,12);l(12,12,16,14,true);dot(19,5);
  }else if(icon==Icons.notifications_none){
   c.drawPath(Path()..moveTo(5,17)..lineTo(7,14)..lineTo(7,9)..cubicTo(7,2,17,2,17,9)..lineTo(17,14)..lineTo(19,17)..close(),p);
   c.drawArc(Rect.fromLTWH(10,18,4,4),0,3.14159,false,accent);dot(18,4);
  }else if(icon==Icons.visibility_outlined||icon==Icons.visibility_off_outlined){
   c.drawPath(Path()..moveTo(2,12)..quadraticBezierTo(12,0,22,12)..quadraticBezierTo(12,24,2,12),p);
   circle(12,12,3,true);
   if(icon==Icons.visibility_off_outlined)l(3,3,21,21);
  }else if(icon==Icons.space_dashboard||icon==Icons.space_dashboard_outlined){
   // Home: a house with a saffron door.
   path([Offset(4,11),Offset(12,4),Offset(20,11),Offset(20,20),Offset(4,20),Offset(4,11)]);
   path([Offset(10,20),Offset(10,15),Offset(14,15),Offset(14,20)],true);
  }else if(icon==Icons.grid_view||icon==Icons.grid_view_outlined){
   box(3,3,7,7);box(14,3,7,7,true);box(3,14,7,7);box(14,14,7,7);
  }else if([Icons.tune,Icons.tune_outlined,Icons.settings_outlined].contains(icon)){
   l(4,7,20,7);l(4,17,20,17);
   c.drawCircle(const Offset(9,7),2.3,Paint()..color=accent.color);c.drawCircle(const Offset(15,17),2.3,Paint()..color=accent.color);
  }else if([Icons.receipt_long,Icons.receipt_long_outlined,Icons.fact_check_outlined].contains(icon)){
   path([Offset(5,21),Offset(5,3),Offset(19,3),Offset(19,21),Offset(16,19),Offset(12,21),Offset(8,19),Offset(5,21)]);
   if(icon==Icons.fact_check_outlined){path([Offset(8,9),Offset(10,11),Offset(15,6)],true);l(8,15,16,15);}
   else{l(8,8,16,8);l(8,12,16,12);l(8,16,12,16,true);}
  }else if([Icons.calendar_today_outlined,Icons.edit_calendar_outlined,Icons.event_outlined,Icons.today].contains(icon)){
   box(3,5,18,16);l(3,10,21,10);l(8,3,8,7,true);l(16,3,16,7,true);
   if(icon==Icons.edit_calendar_outlined){l(12,18,17,13,true);l(11,19,13,18,true);}else{box(8,13,4,4,true);}
  }else if(icon==Icons.add||icon==Icons.remove||icon==Icons.close){
   if(icon==Icons.close){l(6,6,18,18);l(18,6,6,18);}else{l(5,12,19,12);if(icon==Icons.add)l(12,5,12,19);}
  }else if(icon==Icons.chevron_left||icon==Icons.chevron_right){
   final left=icon==Icons.chevron_left;
   path([Offset(left?15:9,5),Offset(left?8:16,12),Offset(left?15:9,19)]);
  }else if(icon==Icons.arrow_back||icon==Icons.undo){
   path([Offset(9,5),Offset(3,11),Offset(9,17)]);
   if(icon==Icons.undo){c.drawPath(Path()..moveTo(3,11)..lineTo(14,11)..quadraticBezierTo(22,11,20,19),p);}
   else{l(3,11,21,11);}
  }else if(icon==Icons.arrow_downward||icon==Icons.arrow_upward){
   final down=icon==Icons.arrow_downward;
   l(12,4,12,20);path([Offset(6,down?14:10),Offset(12,down?20:4),Offset(18,down?14:10)]);
  }else if(icon==Icons.search){circle(10,10,6);l(15,15,21,21,true);
  }else if(icon==Icons.edit_outlined){
   path([Offset(4,20),Offset(5,15),Offset(17,3),Offset(21,7),Offset(9,19),Offset(4,20)]);l(14,6,18,10,true);
  }else if(icon==Icons.history){
   c.drawArc(Rect.fromLTWH(4,4,16,16),-.8,5.5,false,p);path([Offset(3,4),Offset(3,10),Offset(9,10)],true);l(12,7,12,12);l(12,12,16,14,true);
  }else if(icon==Icons.repeat){
   path([Offset(4,9),Offset(4,5),Offset(20,5),Offset(17,2)]);
   path([Offset(20,15),Offset(20,19),Offset(4,19),Offset(7,22)],true);
   l(20,5,17,8);l(4,19,7,16,true);
  }else if(icon==Icons.copy_outlined){box(8,7,13,14);path([Offset(16,3),Offset(3,3),Offset(3,17)],true);
  }else if(icon==Icons.ios_share){
   path([Offset(5,11),Offset(5,21),Offset(19,21),Offset(19,11)]);l(12,3,12,15,true);path([Offset(7,8),Offset(12,3),Offset(17,8)],true);
  }else if(icon==Icons.file_open){
   path([Offset(3,20),Offset(3,4),Offset(12,4),Offset(16,8),Offset(21,8),Offset(18,20),Offset(3,20)]);l(8,13,15,13,true);l(12,10,15,13,true);l(12,16,15,13,true);
  }else if(icon==Icons.bar_chart_rounded||icon==Icons.trending_up){
   path([Offset(3,3),Offset(3,21),Offset(21,21)]);
   if(icon==Icons.bar_chart_rounded){l(8,17,8,12);l(13,17,13,8,true);l(18,17,18,4);}
   else{path([Offset(6,16),Offset(11,11),Offset(14,14),Offset(21,5)],true);path([Offset(16,5),Offset(21,5),Offset(21,10)],true);}
  }else if(icon==Icons.pie_chart_outline){
   c.drawPath(Path()..moveTo(12,3)..arcToPoint(const Offset(21,12),radius:const Radius.circular(9),largeArc:true,clockwise:false)..lineTo(12,12)..close(),p);
   c.drawPath(Path()..moveTo(15,3.5)..arcToPoint(const Offset(20.5,9),radius:const Radius.circular(9))..lineTo(15,9)..close(),accent);
  }else if(icon==Icons.account_balance_wallet_outlined){
   box(3,5,18,15);box(14,10,7,6,true);dot(17,13);l(5,5,17,2);
  }else if(icon==Icons.lock_outline||icon==Icons.lock_open_outlined){
   box(5,10,14,11);
   final shackle=Path()..moveTo(8,10)..lineTo(8,7)..cubicTo(8,1,16,1,16,7);
   if(icon==Icons.lock_outline){shackle.lineTo(16,10);}else{shackle.lineTo(16,8);}
   c.drawPath(shackle,p);circle(12,15,1,true);l(12,16,12,18,true);
  }else if(icon==Icons.dark_mode_outlined){
   c.drawPath(Path()..moveTo(15,3)..cubicTo(3,1,0,19,12,21)..quadraticBezierTo(20,23,22,14)..cubicTo(15,18,9,10,15,3),p);dot(20,5);
  }else if(icon==Icons.light_mode_outlined){
   circle(12,12,4);for(final v in [Offset(12,2),Offset(22,12),Offset(12,22),Offset(2,12)]){final delta=v-Offset(12,12);final start=Offset(12,12)+delta*.7;c.drawLine(start,v,accent);}l(5,5,7,7);l(17,17,19,19);l(5,19,7,17);l(17,7,19,5);
  }else{
   circle(12,12,9);
   if(icon==Icons.check_circle_outline){path([Offset(7,12),Offset(10,15),Offset(17,8)],true);}
   else if(icon==Icons.error_outline){l(12,6,12,13);dot(12,17);}
   else if(icon==Icons.info_outline){dot(12,7);l(12,11,12,17);}
   else{dot(12,12);}
  }
  c.restore();
 }
 @override bool shouldRepaint(covariant _AppPainter old)=>old.icon!=icon||old.color!=color||old.dark!=dark||old.direction!=direction||old.withAccent!=withAccent;
}


