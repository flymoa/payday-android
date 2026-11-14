import 'design_tokens.dart';
import 'localization.dart';
import 'package:flutter/material.dart';
import 'app_icon.dart';

/// Compact balance summary. The whole row opens the existing calculation.
class SafeToSpendRow extends StatelessWidget {
 const SafeToSpendRow({super.key,required this.amount,required this.color,required this.onTap});
 final String amount;
 final Color color;
 final VoidCallback onTap;
 @override Widget build(BuildContext context)=>Semantics(button:true,label:tr(context,'Explain safe to spend'),child:InkWell(
  onTap:onTap,borderRadius:BorderRadius.circular(PaydayRadius.md),
  child:ConstrainedBox(constraints:const BoxConstraints(minHeight:44),child:Row(children:[
   Expanded(flex:5,child:Row(children:[
    Flexible(child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerStart,child:LText('Safe to spend',style:TextStyle(color:color,fontSize:12)))),
    const SizedBox(width:6),Tooltip(message:tr(context,'View safe-to-spend details'),child:PaydayAppIcon(Icons.info_outline,color:color,size:15)),
   ])),
   const SizedBox(width:12),
   Expanded(flex:5,child:FittedBox(fit:BoxFit.scaleDown,alignment:AlignmentDirectional.centerEnd,
    child:LText(amount,textAlign:TextAlign.end,style:TextStyle(color:color,fontSize:14,fontWeight:FontWeight.w800)))),
  ])),
 ));
}

