import 'design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_icon.dart';
import 'brand.dart';

class PaydayAddButton extends StatefulWidget{
 const PaydayAddButton({super.key,required this.onPressed});
 final VoidCallback onPressed;
 @override State<PaydayAddButton> createState()=>_PaydayAddButtonState();
}
class _PaydayAddButtonState extends State<PaydayAddButton>{
 bool pressed=false;
 @override Widget build(BuildContext context){
  final dark=Theme.of(context).brightness==Brightness.dark;
  // Light: raw saffron with a 1px saffronText edge (5.48:1 on sand), so the shape
  // reads at 3:1 though the fill is 1.88:1. Dark: the lifted saffron, already 9:1.
  final fill=dark?PaydayColors.darkSaffron:pressed?PaydayColors.saffronPressed:paydaySaffron;
  return AnimatedScale(
  scale:pressed ? .94 : 1,duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:85),
  child:Material(color:fill,
   shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(PaydayRadius.lg),
    side:dark?BorderSide.none:const BorderSide(color:PaydayColors.saffronEdge)),clipBehavior:Clip.antiAlias,
   child:InkWell(borderRadius:BorderRadius.circular(PaydayRadius.lg),
    splashColor:PaydayColors.emerald.withValues(alpha:.18),highlightColor:PaydayColors.emerald.withValues(alpha:.06),
    onHighlightChanged:(value){if(mounted)setState(()=>pressed=value);},
    onTap:(){HapticFeedback.selectionClick();widget.onPressed();},
    child:const SizedBox(width:48,height:48,child:Center(child:PaydayAppIcon(Icons.add,size:24,color:PaydayColors.ink,accent:true))))));
 }
}
