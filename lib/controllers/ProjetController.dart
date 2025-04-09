import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sunu_projet/models/Projet.dart';
class ProjetController extends GetxController{
  final title =''.obs;
  final description =''.obs;
  final priority =''.obs;
  final statut =''.obs;
  final startdate = Rx<Timestamp>(Timestamp.now());
  final enddate = Rx<Timestamp>(Timestamp.now());
  final projet_title=''.obs;
  final   projetID =''.obs;
  void setProjetDetails(String titletxt ,String descriptiontxt , String prioritytxt,String statutxt,Timestamp end_date ,Timestamp start_date,String  id ){
    title.value = titletxt;
    description.value = descriptiontxt;
    priority.value = prioritytxt;
    statut.value = statutxt;
    startdate.value = start_date;
    enddate.value = end_date;
    projetID.value =id;


  }
  void setProjetTitle(String projet){
    projet_title.value = projet;
  }



}