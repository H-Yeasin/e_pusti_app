enum Division {
  dhaka,
  chattogram,
  rajshahi,
  khulna,
  barishal,
  sylhet,
  rangpur,
  mymensingh,
}

class District {
  const District(this.id, this.division, this.bn, this.en);

  /// Stable id stored with the profile.
  final String id;
  final Division division;
  final String bn;
  final String en;
}

/// The 64 districts of Bangladesh, grouped by division.
const districts = <District>[
  // Dhaka (13)
  District('dhaka', Division.dhaka, 'ঢাকা', 'Dhaka'),
  District('faridpur', Division.dhaka, 'ফরিদপুর', 'Faridpur'),
  District('gazipur', Division.dhaka, 'গাজীপুর', 'Gazipur'),
  District('gopalganj', Division.dhaka, 'গোপালগঞ্জ', 'Gopalganj'),
  District('kishoreganj', Division.dhaka, 'কিশোরগঞ্জ', 'Kishoreganj'),
  District('madaripur', Division.dhaka, 'মাদারীপুর', 'Madaripur'),
  District('manikganj', Division.dhaka, 'মানিকগঞ্জ', 'Manikganj'),
  District('munshiganj', Division.dhaka, 'মুন্সীগঞ্জ', 'Munshiganj'),
  District('narayanganj', Division.dhaka, 'নারায়ণগঞ্জ', 'Narayanganj'),
  District('narsingdi', Division.dhaka, 'নরসিংদী', 'Narsingdi'),
  District('rajbari', Division.dhaka, 'রাজবাড়ী', 'Rajbari'),
  District('shariatpur', Division.dhaka, 'শরীয়তপুর', 'Shariatpur'),
  District('tangail', Division.dhaka, 'টাঙ্গাইল', 'Tangail'),
  // Chattogram (11)
  District('bandarban', Division.chattogram, 'বান্দরবান', 'Bandarban'),
  District(
    'brahmanbaria',
    Division.chattogram,
    'ব্রাহ্মণবাড়িয়া',
    'Brahmanbaria',
  ),
  District('chandpur', Division.chattogram, 'চাঁদপুর', 'Chandpur'),
  District('chattogram', Division.chattogram, 'চট্টগ্রাম', 'Chattogram'),
  District('cumilla', Division.chattogram, 'কুমিল্লা', 'Cumilla'),
  District('coxsbazar', Division.chattogram, 'কক্সবাজার', "Cox's Bazar"),
  District('feni', Division.chattogram, 'ফেনী', 'Feni'),
  District('khagrachhari', Division.chattogram, 'খাগড়াছড়ি', 'Khagrachhari'),
  District('lakshmipur', Division.chattogram, 'লক্ষ্মীপুর', 'Lakshmipur'),
  District('noakhali', Division.chattogram, 'নোয়াখালী', 'Noakhali'),
  District('rangamati', Division.chattogram, 'রাঙ্গামাটি', 'Rangamati'),
  // Rajshahi (8)
  District('bogura', Division.rajshahi, 'বগুড়া', 'Bogura'),
  District('joypurhat', Division.rajshahi, 'জয়পুরহাট', 'Joypurhat'),
  District('naogaon', Division.rajshahi, 'নওগাঁ', 'Naogaon'),
  District('natore', Division.rajshahi, 'নাটোর', 'Natore'),
  District(
    'chapainawabganj',
    Division.rajshahi,
    'চাঁপাইনবাবগঞ্জ',
    'Chapai Nawabganj',
  ),
  District('pabna', Division.rajshahi, 'পাবনা', 'Pabna'),
  District('rajshahi', Division.rajshahi, 'রাজশাহী', 'Rajshahi'),
  District('sirajganj', Division.rajshahi, 'সিরাজগঞ্জ', 'Sirajganj'),
  // Khulna (10)
  District('bagerhat', Division.khulna, 'বাগেরহাট', 'Bagerhat'),
  District('chuadanga', Division.khulna, 'চুয়াডাঙ্গা', 'Chuadanga'),
  District('jashore', Division.khulna, 'যশোর', 'Jashore'),
  District('jhenaidah', Division.khulna, 'ঝিনাইদহ', 'Jhenaidah'),
  District('khulna', Division.khulna, 'খুলনা', 'Khulna'),
  District('kushtia', Division.khulna, 'কুষ্টিয়া', 'Kushtia'),
  District('magura', Division.khulna, 'মাগুরা', 'Magura'),
  District('meherpur', Division.khulna, 'মেহেরপুর', 'Meherpur'),
  District('narail', Division.khulna, 'নড়াইল', 'Narail'),
  District('satkhira', Division.khulna, 'সাতক্ষীরা', 'Satkhira'),
  // Barishal (6)
  District('barguna', Division.barishal, 'বরগুনা', 'Barguna'),
  District('barishal', Division.barishal, 'বরিশাল', 'Barishal'),
  District('bhola', Division.barishal, 'ভোলা', 'Bhola'),
  District('jhalokati', Division.barishal, 'ঝালকাঠি', 'Jhalokati'),
  District('patuakhali', Division.barishal, 'পটুয়াখালী', 'Patuakhali'),
  District('pirojpur', Division.barishal, 'পিরোজপুর', 'Pirojpur'),
  // Sylhet (4)
  District('habiganj', Division.sylhet, 'হবিগঞ্জ', 'Habiganj'),
  District('moulvibazar', Division.sylhet, 'মৌলভীবাজার', 'Moulvibazar'),
  District('sunamganj', Division.sylhet, 'সুনামগঞ্জ', 'Sunamganj'),
  District('sylhet', Division.sylhet, 'সিলেট', 'Sylhet'),
  // Rangpur (8)
  District('dinajpur', Division.rangpur, 'দিনাজপুর', 'Dinajpur'),
  District('gaibandha', Division.rangpur, 'গাইবান্ধা', 'Gaibandha'),
  District('kurigram', Division.rangpur, 'কুড়িগ্রাম', 'Kurigram'),
  District('lalmonirhat', Division.rangpur, 'লালমনিরহাট', 'Lalmonirhat'),
  District('nilphamari', Division.rangpur, 'নীলফামারী', 'Nilphamari'),
  District('panchagarh', Division.rangpur, 'পঞ্চগড়', 'Panchagarh'),
  District('rangpur', Division.rangpur, 'রংপুর', 'Rangpur'),
  District('thakurgaon', Division.rangpur, 'ঠাকুরগাঁও', 'Thakurgaon'),
  // Mymensingh (4)
  District('jamalpur', Division.mymensingh, 'জামালপুর', 'Jamalpur'),
  District('mymensingh', Division.mymensingh, 'ময়মনসিংহ', 'Mymensingh'),
  District('netrokona', Division.mymensingh, 'নেত্রকোনা', 'Netrokona'),
  District('sherpur', Division.mymensingh, 'শেরপুর', 'Sherpur'),
];

District? districtById(String? id) =>
    districts.where((d) => d.id == id).firstOrNull;
