import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/support_point.dart';

const demoPoints = [
  SupportPoint(
      id: 'central',
      name: 'Centro de Apoio Central',
      institution: 'Instituição Solidariedade',
      address: 'Rua Exemplo, 100 · Centro',
      hours: 'Segunda a sexta, das 8h às 18h',
      updatedAt: '14/10/2026, às 10h',
      distanceKm: 1.2,
      resources: [
        Resource('Água potável', 'Água', 'garrafas de 1 L', true, true, 120),
        Resource('Cesta básica', 'Alimentos', 'cestas', true, true, 25),
        Resource('Kit de higiene', 'Higiene', 'kits', false, true, 0),
        Resource('Camiseta', 'Roupas', 'unidades', true, true, 30),
        Resource('Casaco', 'Agasalhos', 'unidades', true, true, 18),
        Resource('Fralda infantil', 'Infantil', 'pacotes', true, true, 20),
      ]),
  SupportPoint(
      id: 'norte',
      name: 'Ponto Comunitário Norte',
      institution: 'Associação Bairro Unido',
      address: 'Avenida Modelo, 250 · Bairro Norte',
      hours: 'Segunda a sexta, das 8h às 17h',
      updatedAt: '14/10/2026, às 9h',
      distanceKm: 2.8,
      resources: [
        Resource('Água potável', 'Água', 'garrafas de 1 L', true, true, null),
        Resource('Cobertor', 'Cobertores', 'unidades', true, true, 40),
        Resource('Tênis', 'Calçados', 'pares', true, true, 15),
        Resource('Calça', 'Roupas', 'unidades', true, true, null),
        Resource('Blusa de frio', 'Agasalhos', 'unidades', true, true, 12),
      ]),
  SupportPoint(
      id: 'sul',
      name: 'Escola de Apoio Sul',
      institution: 'Rede de Apoio Municipal',
      address: 'Rua Ilustrativa, 40 · Bairro Sul',
      hours: 'Segunda a sexta, das 8h às 18h',
      updatedAt: '13/10/2026, às 16h',
      distanceKm: 4.1,
      resources: [
        Resource('Água potável', 'Água', 'garrafas de 1 L', false, true, 0),
        Resource('Cesta básica', 'Alimentos', 'cestas', true, false, 10),
        Resource(
            'Medicamentos básicos', 'Medicamentos', 'caixas', true, true, 24),
        Resource('Vaga de acolhimento', 'Abrigo', 'vagas', true, false, 8),
        Resource('Kit infantil', 'Infantil', 'kits', true, true, 10),
      ])
];
