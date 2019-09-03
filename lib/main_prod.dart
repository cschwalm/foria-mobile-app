
import 'package:foria/utils/configuration.dart';
import 'main.dart';

void main(){
  Configuration.setEnvironment(Environment.PROD);
  mainDelegate();
}