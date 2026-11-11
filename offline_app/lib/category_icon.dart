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
    color:dark?const Color(0xff243F30):const Color(0xffDDEBE2)),
   child:CustomPaint(painter:PaydayGlyphPainter(categoryGlyph(category),dark))));
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
  final teal=Paint()..color=dark?const Color(0xff98CDB5):const Color(0xff0E5A47)
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
   case 'freelance':
    box(4,5,16,11,navy);line(2,19,22,19,teal);line(9,16,8,19,teal);line(15,16,16,19,teal);
    path([Offset(10,8.5),Offset(8,10.5),Offset(10,12.5)],copper);path([Offset(14,8.5),Offset(16,10.5),Offset(14,12.5)],copper);break;
   case 'business':
    box(3,4,18,5,navy,radius:1.5);line(9,4,8,9,teal);line(15,4,16,9,teal);
    path([Offset(5,9),Offset(5,20),Offset(19,20),Offset(19,9)],navy);box(9.5,13,5,7,teal,radius:1);dot(17,15);break;
   case 'gifts':
    box(4,11,16,10,navy);box(3,7,18,4,teal,radius:1.5);line(12,7,12,21,copper);
    canvas.drawPath(Path()..moveTo(12,7)..cubicTo(9,2,5,5,12,7),copper);
    canvas.drawPath(Path()..moveTo(12,7)..cubicTo(15,2,19,5,12,7),copper);break;
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
 @override bool shouldRepaint(covariant PaydayGlyphPainter old)=>old.category!=category||old.dark!=dark;
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
  'groceries':['grocer','food','market','supermarket','courses','marché','épicerie','بقالة','سوق','طعام'],
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
