import 'package:flutter/material.dart';

/// PAYDAY's category glyphs share a 24-unit grid and rounded strokes.
/// Drawn as vectors so they stay sharp without image assets or dependencies.
class PaydayCategoryIcon extends StatelessWidget {
 const PaydayCategoryIcon(this.category,{super.key,this.size=40});
 final String category;
 final double size;
 @override Widget build(BuildContext context){
  final dark=Theme.of(context).brightness==Brightness.dark;
  return ExcludeSemantics(child:Container(width:size,height:size,
   padding:EdgeInsets.all(size*.20),
   decoration:BoxDecoration(shape:BoxShape.circle,
    color:dark?const Color(0xff234D3D):const Color(0xffDDEBE2)),
   child:CustomPaint(painter:PaydayGlyphPainter(category.trim().toLowerCase(),dark))));
 }
}

class PaydayGlyphPainter extends CustomPainter {
 const PaydayGlyphPainter(this.category,this.dark,{this.foreground});
 final Color? foreground;
 final String category;
 final bool dark;
 @override void paint(Canvas canvas,Size size){
  canvas.save();canvas.scale(size.width/24,size.height/24);
  final navy=Paint()..color=foreground??(dark?const Color(0xffE2EAF0):const Color(0xff0E5A47))
   ..style=PaintingStyle.stroke..strokeWidth=1.65..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  final teal=Paint()..color=dark?const Color(0xff68C7BA):const Color(0xff0E5A47)
   ..style=PaintingStyle.stroke..strokeWidth=1.65..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  final copper=Paint()..color=dark?const Color(0xffE7AD79):const Color(0xffF4A62A)
   ..style=PaintingStyle.stroke..strokeWidth=1.65..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  void line(double x,double y,double x2,double y2,Paint p)=>canvas.drawLine(Offset(x,y),Offset(x2,y2),p);
  void path(List<Offset> points,Paint p,{bool close=false}){
   final q=Path()..moveTo(points.first.dx,points.first.dy);
   for(final point in points.skip(1)){q.lineTo(point.dx,point.dy);}if(close)q.close();canvas.drawPath(q,p);
  }
  void box(double x,double y,double w,double h,Paint p,{double radius=2})=>canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),Radius.circular(radius)),p);
  void dot(double x,double y)=>canvas.drawCircle(Offset(x,y),.95,Paint()..color=copper.color);
  switch(category){
   case 'housing':
    path([Offset(3,11),Offset(12,3.5),Offset(21,11)],navy);
    path([Offset(5,10),Offset(5,20),Offset(19,20),Offset(19,10)],teal);
    box(10,13,4,7,navy,radius:1);dot(17,7);break;
   case 'utilities':
    canvas.drawPath(Path()..moveTo(12,3)..cubicTo(10,6,5,11,5,15)..cubicTo(5,23,19,23,19,15)..cubicTo(19,11,14,6,12,3),navy);
    path([Offset(13,9),Offset(9,14),Offset(13,14),Offset(11,18)],teal);dot(18,6);break;
   case 'groceries':
    path([Offset(3,10),Offset(5.5,20),Offset(18.5,20),Offset(21,10)],navy);
    line(3,10,21,10,teal);line(7,10,10,5,navy);line(17,10,14,5,navy);
    line(9,14,9.5,17,teal);line(15,14,14.5,17,teal);
    canvas.drawPath(Path()..moveTo(12,7)..quadraticBezierTo(12,2,17,3)..quadraticBezierTo(17,7,12,7),copper);break;
   case 'transport':
    path([Offset(5,10),Offset(7,5),Offset(17,5),Offset(19,10)],teal);
    box(3,10,18,8,navy);line(6,18,6,20,navy);line(18,18,18,20,navy);
    line(7,14,8,14,copper);line(16,14,17,14,copper);line(10,21,14,21,teal);break;
   case 'health':
    canvas.drawPath(Path()..moveTo(12,20)..cubicTo(8,17,3,13,3,8)..cubicTo(3,3,9,2,12,7)..cubicTo(15,2,21,3,21,8)..cubicTo(21,13,16,17,12,20),navy);
    line(9,11,15,11,teal);line(12,8,12,14,teal);dot(19,17);break;
   case 'family':
    canvas.drawCircle(Offset(8,9),2.4,navy);canvas.drawCircle(Offset(16,10),2,teal);
    canvas.drawPath(Path()..moveTo(3,20)..quadraticBezierTo(3,13,8,13)..quadraticBezierTo(13,13,13,20),navy);
    canvas.drawPath(Path()..moveTo(13,16)..quadraticBezierTo(20,13,21,20),teal);
    canvas.drawPath(Path()..moveTo(4,4)..quadraticBezierTo(12,-.5,20,4),copper);break;
   case 'eating out':
    canvas.drawPath(Path()..moveTo(3,12)..quadraticBezierTo(4,20,12,20)..quadraticBezierTo(20,20,21,12)..close(),navy);
    line(3,12,21,12,teal);line(8,22,16,22,teal);
    canvas.drawPath(Path()..moveTo(8,8)..cubicTo(5,5,10,5,8,2),teal);
    canvas.drawPath(Path()..moveTo(15,8)..cubicTo(12,5,17,5,15,2),copper);break;
   case 'shopping':
    box(4,8,16,13,navy);canvas.drawPath(Path()..moveTo(8,9)..lineTo(8,6)..cubicTo(8,1,16,1,16,6)..lineTo(16,9),teal);
    path([Offset(16,12),Offset(19,12),Offset(19,16),Offset(16,18),Offset(14,15),Offset(16,12)],copper);break;
   case 'subscriptions':
    canvas.drawPath(Path()..moveTo(4,10)..cubicTo(4,2,17,1,20,8),navy);
    path([Offset(16,7),Offset(20,8),Offset(21,4)],copper);
    canvas.drawPath(Path()..moveTo(20,14)..cubicTo(20,22,7,23,4,16),teal);
    path([Offset(8,17),Offset(4,16),Offset(3,20)],copper);
    path([Offset(10,8),Offset(16,12),Offset(10,16)],teal,close:true);break;
   case 'leisure':
    box(3,8,18,11,navy,radius:4);line(6,13,11,13,teal);line(8.5,10.5,8.5,15.5,teal);
    dot(16,12);dot(18,15);canvas.drawPath(Path()..moveTo(12,8)..quadraticBezierTo(10,3,15,3),teal);break;
   case 'debt payment':
    box(3,5,18,14,navy);line(3,9,21,9,teal);line(6,14,10,14,teal);
    path([Offset(14,13),Offset(17,16),Offset(21,12)],copper);break;
   case 'income':
    canvas.drawPath(Path()..moveTo(5,4)..lineTo(5,18)..quadraticBezierTo(5,21,8,21)..lineTo(19,21),navy);
    path([Offset(19,4),Offset(9,14),Offset(9,8)],teal);
    line(9,14,15,14,teal);dot(20,15);break;
   case 'expense':
    canvas.drawPath(Path()..moveTo(5,4)..lineTo(5,18)..quadraticBezierTo(5,21,8,21)..lineTo(19,21),navy);
    path([Offset(9,14),Offset(19,4),Offset(13,4)],teal);
    line(19,4,19,10,teal);dot(20,15);break;
   case 'reserve':
    box(3,5,18,16,navy,radius:3);line(3,10,21,10,teal);
    line(8,3,8,7,teal);line(16,3,16,7,teal);
    canvas.drawCircle(Offset(12,15),3.4,copper);
    line(12,13,12,15,copper);line(12,15,14,16,copper);break;
   case 'salary':
   case 'income plan':
    box(3,9,18,12,navy);canvas.drawPath(Path()..moveTo(8,9)..lineTo(8,5)..lineTo(16,5)..lineTo(16,9),teal);
    line(3,14,21,14,teal);box(10,12,4,4,copper,radius:1);break;
   case 'savings':
   case 'savings goal':
    box(4,10,16,11,navy,radius:4);line(9,13,15,13,teal);
    canvas.drawCircle(Offset(12,5),3,copper);line(12,3.5,12,6.5,copper);break;
   default:
    box(3,3,7,7,navy);box(14,3,7,7,teal);box(3,14,7,7,teal);box(14,14,7,7,copper);break;
  }
  canvas.restore();
 }
 @override bool shouldRepaint(covariant PaydayGlyphPainter old)=>old.category!=category||old.dark!=dark;
}



