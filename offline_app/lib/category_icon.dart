import 'design_tokens.dart';
import 'canvas_icons.dart';
import 'package:flutter/material.dart';

/// PAYDAY's category glyphs share a 24-unit grid and rounded strokes.
/// Drawn as vectors so they stay sharp without image assets or dependencies.
class PaydayCategoryIcon extends StatelessWidget {
 const PaydayCategoryIcon(this.category,{super.key,this.size=40,this.bare=false});
 final String category;
 final double size;
 /// Just the glyph, without its tile (category picker).
 final bool bare;
 @override Widget build(BuildContext context){
  final dark=Theme.of(context).brightness==Brightness.dark;
  final glyph=CustomPaint(painter:CanvasGlyphPainter(canvasGlyphForCategory(categoryGlyph(category)),
   dark?PaydayColors.darkIcon:PaydayColors.emerald));
  if(bare)return ExcludeSemantics(child:SizedBox.square(dimension:size,child:glyph));
  // Rounded tile with a stroke glyph, as on the design canvas.
  return ExcludeSemantics(child:Container(width:size,height:size,
   padding:EdgeInsets.all(size*.24),
   decoration:BoxDecoration(borderRadius:BorderRadius.circular(PaydayRadius.lg),color:canvasTileColor(dark)),
   child:glyph));
 }
}

class PaydayGlyphPainter extends CustomPainter {
 const PaydayGlyphPainter(this.category,this.dark,{this.foreground,this.accent=false});
 final Color? foreground;
 /// Saffron detail stroke; off by default (saffron is reserved for the add button).
 final bool accent;
 final String category;
 final bool dark;
 @override void paint(Canvas canvas,Size size){
  canvas.save();canvas.scale(size.width/24,size.height/24);
  final navy=Paint()..color=foreground??(dark?PaydayColors.darkIcon:PaydayColors.emerald)
   ..style=PaintingStyle.stroke..strokeWidth=1.65..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  final teal=Paint()..color=dark?PaydayColors.darkPrimary:PaydayColors.emerald
   ..style=PaintingStyle.stroke..strokeWidth=1.65..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  final copper=Paint()..color=accent?(dark?PaydayColors.darkCopper:PaydayColors.saffron):navy.color
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
    path([Offset(4,11),Offset(12,4),Offset(20,11),Offset(20,20),Offset(4,20)],navy,close:true);
    path([Offset(10,20),Offset(10,15),Offset(14,15),Offset(14,20)],copper);break;
   case 'utilities':
    canvas.drawPath(Path()..moveTo(12,3)..cubicTo(15,7,17,9.5,17,12)..arcToPoint(Offset(7,12),radius:Radius.circular(5))..cubicTo(7,9.5,9,7,12,3)..close(),navy);
    path([Offset(12.5,9.5),Offset(10,13),Offset(14,13),Offset(11.5,16.5)],copper);break;
   case 'groceries':
    path([Offset(4,9),Offset(20,9),Offset(18.5,20),Offset(5.5,20)],navy,close:true);
    line(8,9,11,4,navy);line(16,9,13,4,navy);
    line(9,13,9,17,copper);line(12,13,12,17,copper);line(15,13,15,17,copper);break;
   case 'transport':
    path([Offset(5,16),Offset(5,10),Offset(7,6),Offset(17,6),Offset(19,10),Offset(19,16)],navy,close:true);
    line(5,16,5,18.5,navy);line(19,16,19,18.5,navy);
    canvas.drawCircle(Offset(8.5,13),1.1,Paint()..color=copper.color);canvas.drawCircle(Offset(15.5,13),1.1,Paint()..color=copper.color);break;
   case 'health':
    canvas.drawPath(Path()..moveTo(12,20)..cubicTo(8,17,3,13.5,3,9)..cubicTo(3,4,9,3,12,7.5)..cubicTo(15,3,21,4,21,9)..cubicTo(21,13.5,16,17,12,20),navy);
    line(9,12,15,12,copper);line(12,9,12,15,copper);break;
   case 'family':
    canvas.drawCircle(Offset(8,8),3,navy);canvas.drawCircle(Offset(16,9),2.5,navy);
    canvas.drawPath(Path()..moveTo(3,20)..cubicTo(3,17,5.5,15,8,15)..cubicTo(10.5,15,13,17,13,20),navy);
    canvas.drawPath(Path()..moveTo(13.5,20)..cubicTo(13.8,17.7,14.9,16,16.5,16)..cubicTo(18.1,16,19.5,17.7,19.5,20),copper);break;
   case 'eating out':
    canvas.drawPath(Path()..moveTo(4,12)..lineTo(20,12)..arcToPoint(Offset(4,12),radius:Radius.circular(8))..close(),navy);
    line(8,20.5,16,20.5,navy);
    canvas.drawPath(Path()..moveTo(9,3.5)..cubicTo(10.3,4.8,7.7,5.7,9,7.5),copper);
    canvas.drawPath(Path()..moveTo(14,3.5)..cubicTo(15.3,4.8,12.7,5.7,14,7.5),copper);break;
   case 'shopping':
    box(4,8,16,13,navy);canvas.drawPath(Path()..moveTo(8,9)..lineTo(8,6)..cubicTo(8,1,16,1,16,6)..lineTo(16,9),teal);
    path([Offset(16,12),Offset(19,12),Offset(19,16),Offset(16,18),Offset(14,15),Offset(16,12)],copper);break;
   case 'subscriptions':
    canvas.drawPath(Path()..moveTo(4,12)..arcToPoint(Offset(18,6.7),radius:Radius.circular(8)),navy);
    canvas.drawPath(Path()..moveTo(20,12)..arcToPoint(Offset(6,17.3),radius:Radius.circular(8)),navy);
    path([Offset(18,3),Offset(18,7),Offset(14,7)],copper);path([Offset(6,21),Offset(6,17),Offset(10,17)],copper);break;
   case 'leisure':
    box(3,8.5,18,10,navy,radius:4.5);line(7,12,7,15,navy);line(5.5,13.5,8.5,13.5,navy);
    canvas.drawCircle(Offset(16,12.5),1.1,Paint()..color=copper.color);canvas.drawCircle(Offset(17.8,14.8),1.1,Paint()..color=copper.color);break;
   case 'debt payment':
    box(3,6,18,12,navy);line(3,10,21,10,navy);line(6,14.5,10,14.5,copper);break;
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
    box(4,8,16,12,navy);path([Offset(9,8),Offset(9,5),Offset(15,5),Offset(15,8)],navy);
    line(4,13,20,13,navy);canvas.drawCircle(Offset(12,13),1.7,Paint()..color=copper.color);break;
   case 'savings':
   case 'savings goal':
    box(4,10,16,11,navy,radius:2.5);line(8,15,16,15,navy);
    canvas.drawCircle(Offset(12,5.5),2.5,copper);break;
   case 'freelance':
    box(4,5,16,11,navy);line(2,19,22,19,teal);line(9,16,8,19,teal);line(15,16,16,19,teal);
    path([Offset(10,8.5),Offset(8,10.5),Offset(10,12.5)],copper);path([Offset(14,8.5),Offset(16,10.5),Offset(14,12.5)],copper);break;
   case 'business':
    box(3,4,18,5,navy,radius:1.5);line(9,4,8,9,teal);line(15,4,16,9,teal);
    path([Offset(5,9),Offset(5,20),Offset(19,20),Offset(19,9)],navy);box(9.5,13,5,7,teal,radius:1);dot(17,15);break;
   case 'gifts':
    box(4,11,16,9,navy);box(3,7,18,4,navy,radius:1.5);line(12,7,12,20,navy);
    canvas.drawPath(Path()..moveTo(12,7)..cubicTo(10,4,7,4,7,5.5)..cubicTo(7,7,10,7,12,7),copper);
    canvas.drawPath(Path()..moveTo(12,7)..cubicTo(14,4,17,4,17,5.5)..cubicTo(17,7,14,7,12,7),copper);break;
   case 'other income':
    canvas.drawCircle(Offset(12,13),7.5,navy);line(12,9.5,12,16.5,teal);line(8.5,13,15.5,13,teal);
    path([Offset(17,4),Offset(20,4),Offset(20,7)],copper);line(15,9,20,4,copper);break;
   case 'other':
    canvas.drawCircle(Offset(12,12),8.5,navy);
    for(final x in [8.0,12.0,16.0]){canvas.drawCircle(Offset(x,12),1.25,Paint()..color=(x==16?copper:teal).color);}break;
   case 'education':
    path([Offset(2,9),Offset(12,4),Offset(22,9),Offset(12,14)],navy,close:true);
    path([Offset(6,11),Offset(6,16),Offset(12,19),Offset(18,16),Offset(18,11)],teal);
    line(21,9,21,14,copper);dot(21,15.5);break;
   case 'pets':
    canvas.drawOval(Rect.fromCenter(center:Offset(12,16),width:9,height:7),navy);
    for(final o in [Offset(5.5,10.5),Offset(9.5,6),Offset(14.5,6),Offset(18.5,10.5)]){canvas.drawCircle(o,1.8,teal);}
    dot(12,16);break;
   case 'travel':
    box(4,8,16,12,navy,radius:2.5);path([Offset(9,8),Offset(9,5),Offset(15,5),Offset(15,8)],teal);
    line(8,8,8,20,teal);line(16,8,16,20,teal);line(10,22,10,20,navy);line(14,22,14,20,navy);dot(12,14);break;
   default: // a neutral price tag for anything not recognised
    path([Offset(3,12),Offset(11,4),Offset(20,4),Offset(20,13),Offset(12,21)],navy,close:true);
    canvas.drawCircle(Offset(16,8),1.6,copper);line(9,12,13,16,teal);break;
  }
  canvas.restore();
 }
 @override bool shouldRepaint(covariant PaydayGlyphPainter old)=>old.category!=category||old.dark!=dark||old.accent!=accent||old.foreground!=foreground;
}





/// Built-in names map directly; a category the user created gets the closest
/// glyph from words in its name (English, French and Arabic), else a tag.
String categoryGlyph(String name){
 final n=name.trim().toLowerCase();
 const direct={'housing','utilities','groceries','transport','health','family','eating out','shopping','subscriptions',
  'leisure','debt payment','income','expense','reserve','salary','income plan','savings','savings goal','freelance',
  'business','gifts','other income','other','education','pets','travel'};
 if(direct.contains(n))return n;
 if(n=='uncategorized')return 'tag';
 const words=<String,List<String>>{
  'housing':['rent','home','house','mortgage','apartment','flat','loyer','maison','logement','إيجار','كراء','سكن','منزل'],
  'utilities':['electric','water','gas','internet','wifi','phone','mobile','bill','électricité','eau','téléphone','كهرباء','ماء','هاتف','انترنت'],
  'groceries':['grocer','food','market','supermarket','courses','marché','épicerie','بقالة','سوق','طعام','غذائية','مواد'],
  'transport':['car','fuel','petrol','taxi','bus','train','tram','uber','parking','transport','voiture','essence','carburant','سيارة','بنزين','نقل'],
  'health':['doctor','pharmacy','medic','health','gym','sport','dentist','santé','pharmacie','médecin','صحة','دواء','طبيب'],
  'family':['kid','child','baby','family','parent','enfant','famille','أطفال','عائلة'],
  'eating out':['restaurant','cafe','café','coffee','lunch','dinner','takeaway','resto','مطعم','قهوة'],
  'shopping':['cloth','shop','fashion','amazon','vêtement','shopping','ملابس','تسوق'],
  'subscriptions':['netflix','spotify','subscription','abonnement','streaming','اشتراك'],
  'leisure':['movie','cinema','game','hobby','fun','concert','loisir','sortie','ترفيه','سينما'],
  'debt payment':['loan','debt','credit','prêt','crédit','dette','قرض','دين'],
  'education':['school','course','book','education','study','university','tuition','école','cours','livre','formation','مدرسة','دراسة','كتاب','تعليم'],
  'pets':['pet','dog','cat','vet','animal','chien','chat','vétérinaire','حيوان','قط','كلب'],
  'travel':['travel','trip','holiday','flight','hotel','vacation','voyage','vacances','avion','سفر','عطلة','فندق'],
  'gifts':['gift','present','wedding','birthday','cadeau','mariage','هدية','عرس'],
  'salary':['salary','wage','payroll','salaire','paie','راتب','أجر'],
  'freelance':['freelance','client','contract','mission','عمل حر'],
  'business':['business','sales','store','entreprise','commerce','vente','تجارة','مبيعات'],
  'savings':['saving','épargne','ادخار','توفير'],
 };
 for(final entry in words.entries){if(entry.value.any(n.contains))return entry.key;}
 return 'tag';
}
