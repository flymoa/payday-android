import 'localization.dart';
import 'package:flutter/material.dart';

/// The existing segmented PAYDAY line, driven by this month's real usage.
class MonthUsageBar extends StatelessWidget {
 const MonthUsageBar({super.key,required this.value,required this.trackColor,
  required this.fillColor,required this.markerColor});
 final double value;
 final Color trackColor,fillColor,markerColor;
 @override Widget build(BuildContext context){
  final target=value.clamp(0,1).toDouble();
  return Semantics(label:tr(context,'Money used this month'),value:'${(target*100).round()}%',
   child:ExcludeSemantics(child:TweenAnimationBuilder<double>(
    tween:Tween(begin:0,end:target),duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:250),
    builder:(context,progress,child){
     final last=(progress*27).round();
     return SizedBox(height:27,child:Row(crossAxisAlignment:CrossAxisAlignment.end,
      children:List.generate(28,(i){
       final fill=(progress*28-i).clamp(0,1).toDouble();
       return Expanded(child:Padding(padding:const EdgeInsetsDirectional.only(end:3),
        child:SizedBox(height:i==last?27:15,child:ClipRRect(
         borderRadius:BorderRadius.circular(4),child:Stack(fit:StackFit.expand,children:[
          ColoredBox(color:trackColor),
          if(i==last)ColoredBox(key:const ValueKey('month-usage-marker'),color:markerColor)
          else FractionallySizedBox(alignment:AlignmentDirectional.centerStart,widthFactor:fill,
           child:ColoredBox(color:fillColor)),
         ])))));
      })));
    })));
 }
}


