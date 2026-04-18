class BDLocations {
  static const Map<String, Map<String, List<String>>> data = {
    'Dhaka': {
      'Dhaka District': ['Dhanmondi', 'Gulshan', 'Mirpur', 'Uttara', 'Tejgaon'],
      'Gazipur': ['Gazipur Sadar', 'Kaliakair', 'Kaliganj', 'Kapasia', 'Sreepur'],
      'Narayanganj': ['Narayanganj Sadar', 'Bandar', 'Fatullah', 'Siddhirganj', 'Araihazar'],
    },
    'Chattogram': {
      'Chattogram District': ['Panchlaish', 'Double Mooring', 'Kotwali', 'Halishahar'],
      'Cox\'s Bazar': ['Cox\'s Bazar Sadar', 'Chakaria', 'Maheshkhali', 'Teknaf'],
    },
    'Rajshahi': {
      'Rajshahi District': ['Boalia', 'Motihar', 'Rajpara', 'Shah Makhdum'],
      'Bogra': ['Bogra Sadar', 'Adamdighi', 'Dhunat', 'Gabtali'],
    },
    'Khulna': {
      'Khulna District': ['Khulna Sadar', 'Daulatpur', 'Khalishpur', 'Khan Jahan Ali'],
      'Jashore': ['Jashore Sadar', 'Abhaynagar', 'Bagherpara', 'Chaugachha'],
    },
    'Sylhet': {
      'Sylhet District': ['Sylhet Sadar', 'Beanibazar', 'Bishwanath', 'Fenchuganj'],
      'Moulvibazar': ['Moulvibazar Sadar', 'Barlekha', 'Kamalganj', 'Kulaura'],
    },
    'Barishal': {
      'Barishal District': ['Barishal Sadar', 'Agailjhara', 'Babuganj', 'Bakerganj'],
      'Bhola': ['Bhola Sadar', 'Burhanuddin', 'Char Fasson', 'Daulatkhan'],
    },
    'Rangpur': {
      'Rangpur District': ['Rangpur Sadar', 'Badarganj', 'Gangachara', 'Kaunia'],
      'Dinajpur': ['Dinajpur Sadar', 'Birganj', 'Biral', 'Bochaganj'],
    },
    'Mymensingh': {
      'Mymensingh District': ['Mymensingh Sadar', 'Bhaluka', 'Dhobaura', 'Fulbaria'],
      'Netrokona': ['Netrokona Sadar', 'Atpara', 'Barhatta', 'Durgapur'],
    },
  };

  static List<String> get divisions => data.keys.toList();

  static List<String> getDistricts(String division) {
    return data[division]?.keys.toList() ?? [];
  }

  static List<String> getUpazilas(String division, String district) {
    return data[division]?[district] ?? [];
  }
}
