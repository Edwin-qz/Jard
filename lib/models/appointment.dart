class Appointment {
  final String id;
  final String title;
  final String clientName;
  final String clientPhone;
  final String propertyType;
  final String address;
  final String time;
  final String dateDay;
  final String dateMonth;
  final String status; // 'Confirmada', 'Por confirmar', 'Completada'
  final bool isNextHero;
  final String? imagePath;
  final double latitude;
  final double longitude;

  Appointment({
    required this.id,
    required this.title,
    required this.clientName,
    this.clientPhone = '9994192883',
    required this.propertyType,
    required this.address,
    required this.time,
    required this.dateDay,
    required this.dateMonth,
    required this.status,
    this.isNextHero = false,
    this.imagePath,
    this.latitude = 20.9984,
    this.longitude = -89.5849,
  });

  Appointment copyWith({
    String? id,
    String? title,
    String? clientName,
    String? clientPhone,
    String? propertyType,
    String? address,
    String? time,
    String? dateDay,
    String? dateMonth,
    String? status,
    bool? isNextHero,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      propertyType: propertyType ?? this.propertyType,
      address: address ?? this.address,
      time: time ?? this.time,
      dateDay: dateDay ?? this.dateDay,
      dateMonth: dateMonth ?? this.dateMonth,
      status: status ?? this.status,
      isNextHero: isNextHero ?? this.isNextHero,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static List<Appointment> sampleAppointments() {
    return [
      Appointment(
        id: '1',
        title: 'Instalación de pasto',
        clientName: 'Casa Rivera',
        clientPhone: '9994192883',
        propertyType: 'Residencial',
        address: 'Casa Rivera • Fracc. Altabrisa, Mérida, Yucatán',
        time: '9:30 AM',
        dateDay: '18',
        dateMonth: 'JUN',
        status: 'Confirmada',
        isNextHero: true,
        imagePath: 'assets/images/hero_gardener.jpg',
        latitude: 20.9984,
        longitude: -89.5849,
      ),
      Appointment(
        id: '2',
        title: 'Poda y mantenimiento',
        clientName: 'Mariana Ortega',
        clientPhone: '9998124567',
        propertyType: 'Jardín residencial',
        address: 'Residencial Montebello, Mérida, Yucatán',
        time: '12:30 PM',
        dateDay: '18',
        dateMonth: 'JUN',
        status: 'Confirmada',
        latitude: 21.0261,
        longitude: -89.5932,
      ),
      Appointment(
        id: '3',
        title: 'Visita de valoración',
        clientName: 'Hotel Casa Verde',
        clientPhone: '9999238810',
        propertyType: 'Paisajismo',
        address: 'Paseo de Montejo #480, Centro, Mérida, Yucatán',
        time: '4:00 PM',
        dateDay: '18',
        dateMonth: 'JUN',
        status: 'Por confirmar',
        latitude: 20.9822,
        longitude: -89.6190,
      ),
      Appointment(
        id: '4',
        title: 'Fumigación y control de plagas',
        clientName: 'Roberto Salas',
        clientPhone: '9993456789',
        propertyType: 'Residencia privada',
        address: 'Calle 21, Cholul, Yucatán',
        time: '10:00 AM',
        dateDay: '19',
        dateMonth: 'JUN',
        status: 'Confirmada',
        latitude: 21.0345,
        longitude: -89.5532,
      ),
    ];
  }
}
