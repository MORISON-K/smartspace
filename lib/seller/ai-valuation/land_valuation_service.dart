import 'package:smartspace/seller/ai-valuation/property_input.dart';

class LandValuationService {
  // Temporary static base prices by district (UGX per acre)
  final Map<String, double> basePrices = {
    "Kampala": 90000000,
    "Wakiso": 40000000,
    "Mukono": 35000000,
    "Mbarara": 20000000,
    "Gulu": 18000000,
    "Other": 10000000,
  };

  double getBasePricePerAcre(String district) {
    return basePrices[district] ?? basePrices["Other"]!;
  }

  double calculateModifiers(PropertyInput input) {
    double modifier = 0;

    // Title
    if (input.isTitled) {
      modifier += 0.15;
    } else {
      modifier -= 0.10;
    }

    // Road access
    if (input.nearTarmac) {
      modifier += 0.10;
    } else {
      modifier -= 0.05;
    }

    // Utilities
    if (input.powerNearby) modifier += 0.05;
    if (input.waterAvailable) modifier += 0.05;

    // Terrain
    if (input.terrain == "Flat") {
      modifier += 0.10;
    } else if (input.terrain == "Swampy" || input.terrain == "Rocky") {
      modifier -= 0.10;
    }

    // Distance to town
    if (input.distanceToTownKm <= 2) {
      modifier += 0.10;
    } else if (input.distanceToTownKm > 5) {
      modifier -= 0.05;
    }

    // Land use
    if (input.landUse == "Commercial" || input.landUse == "Mixed-use") {
      modifier += 0.20;
    }

    return modifier;
  }

  double estimateFinalPrice(PropertyInput input) {
    double basePricePerAcre = getBasePricePerAcre(input.locationDistrict);
    double basePrice = input.sizeInAcres * basePricePerAcre;
    double modifier = calculateModifiers(input);
    return basePrice * (1 + modifier);
  }

  String explainModifiers(PropertyInput input) {
    //  explain breakdown for UI
    List<String> notes = [];

    if (input.isTitled) {
      notes.add("+15% for titled land");
    } else {
      notes.add("-10% for untitled land");
    }

    if (input.nearTarmac) {
      notes.add("+10% for near tarmac road");
    } else {
      notes.add("-5% for poor road access");
    }

    if (input.powerNearby) notes.add("+5% for electricity nearby");
    if (input.waterAvailable) notes.add("+5% for water availability");

    if (input.terrain == "Flat") {
      notes.add("+10% for flat terrain");
    } else {
      notes.add("-10% for rough/swampy land");
    }

    if (input.distanceToTownKm <= 2) {
      notes.add("+10% for being close to town");
    } else if (input.distanceToTownKm > 5) {
      notes.add("-5% for being far from town");
    }

    if (input.landUse == "Commercial" || input.landUse == "Mixed-use") {
      notes.add("+20% for commercial land");
    }

    return notes.join(", ");
  }
}
