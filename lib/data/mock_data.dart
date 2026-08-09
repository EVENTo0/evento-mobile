import 'package:flutter/material.dart';

class ServiceItem {
  const ServiceItem({
    required this.icon,
    required this.ar,
    required this.en,
    required this.detailAr,
    required this.detailEn,
  });

  final IconData icon;
  final String ar;
  final String en;
  final String detailAr;
  final String detailEn;
}

const List<ServiceItem> services = <ServiceItem>[
  ServiceItem(
    icon: Icons.language_rounded,
    ar: 'مواقع ومنصات',
    en: 'Web & Platforms',
    detailAr: 'مواقع أعمال، متاجر، منصات وخدمات رقمية.',
    detailEn: 'Business sites, stores, platforms and digital services.',
  ),
  ServiceItem(
    icon: Icons.phone_iphone_rounded,
    ar: 'تطبيقات الهاتف',
    en: 'Mobile Apps',
    detailAr: 'تطبيقات iOS وAndroid من قاعدة Flutter واحدة.',
    detailEn: 'iOS and Android apps from one Flutter codebase.',
  ),
  ServiceItem(
    icon: Icons.auto_awesome_rounded,
    ar: 'حلول الذكاء الاصطناعي',
    en: 'AI Solutions',
    detailAr: 'وكلاء، أتمتة، مساعدين وأنظمة ذكية مع ضوابط وتقييم.',
    detailEn: 'Agents, automation, assistants and AI systems with guardrails and evaluation.',
  ),
  ServiceItem(
    icon: Icons.sports_esports_rounded,
    ar: 'ألعاب وتجارب تفاعلية',
    en: 'Games & Interactive',
    detailAr: 'نماذج ألعاب وتجارب 3D وVR/XR من الفكرة إلى النموذج القابل للعب.',
    detailEn: 'Games, 3D and VR/XR experiences from concept to playable prototype.',
  ),
  ServiceItem(
    icon: Icons.dashboard_customize_rounded,
    ar: 'لوحات وأنظمة تشغيل',
    en: 'Dashboards & Control Systems',
    detailAr: 'لوحات إدارة، مراكز قيادة، مراقبة المشاريع والعمليات.',
    detailEn: 'Admin dashboards, control planes, project and operations monitoring.',
  ),
];
