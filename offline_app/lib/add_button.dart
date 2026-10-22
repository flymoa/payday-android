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
 @override Widget build(BuildContext context)=>AnimatedScale(
  scale:pressed ? .94 : 1,duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:85),
  child:Material(color:pressed?const Color(0xffE99A1D):paydaySaffron,
   borderRadius:BorderRadius.circular(17),clipBehavior:Clip.antiAlias,
   child:InkWell(borderRadius:BorderRadius.circular(17),
    splashColor:const Color(0xff0E5A47).withValues(alpha:.18),highlightColor:const Color(0xff0E5A47).withValues(alpha:.06),
    onHighlightChanged:(value){if(mounted)setState(()=>pressed=value);},
    onTap:(){HapticFeedback.selectionClick();widget.onPressed();},
    child:const SizedBox(width:48,height:48,child:Center(child:PaydayAppIcon(Icons.add,size:24,color:Color(0xff12261F)))))));
}
