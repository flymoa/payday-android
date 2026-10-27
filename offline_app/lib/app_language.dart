const paydayLanguages={'en':'English','fr':'Français','ar':'العربية'};
String supportedLanguage(String? value)=>paydayLanguages.containsKey(value)?value!:'en';
abstract interface class NotificationLanguagePlatform{
 void setLanguage(String language);
}
