import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/widgets/fridge_bottom_navigation.dart';

class FridgeGridScreen extends StatelessWidget {
  const FridgeGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'My Fridge',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.black),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Items', true),
                  _buildFilterChip('🥕 Produce', false),
                  _buildFilterChip('🥩 Meat', false),
                  _buildFilterChip('🥛 Dairy', false),
                  _buildFilterChip('⚠️ Expiring', false, isWarning: true),
                ],
              ),
            ),
          ),
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
                children: [
                  _buildItemCard(
                    context,
                    'Mixed Veggies',
                    'Fresh',
                    '5 days left',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAu1KXQwW-2d40Vp0vWOQMq1H4a6-re4Ol-PU07qolU9u3cDtIosgD4ytTzUX29ws-VdA3drnjvOLLw0eT7rQLRQIpPWBAvsvDZjkFSgAFBGRILvAIQNRevF3D_XK9tk60MeqDSN2OsecHzyrVRXbzkbFHkKr4y5CP6l2U0MEQO3doDCDla4MAUAyfjjwuUbOBhekZCx_RQEq-tu3lKe8nuI7ynuH5-jb6z9Hn8k7VdwkXsK2LM8TIQ7syN1rxrrW_X1OACmPUGq1QW',
                    statusColor: const Color(0xFF13EC13),
                  ),
                  _buildItemCard(
                    context,
                    'Whole Milk',
                    'Opened',
                    '2 days left',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB9uPpk_Q7Z3UmT0xafYFq-T762teInOhze0NDPK964Pc-guhKIN5O4WBhOVvwpRCn6DDKtsrD5isIb9Q4QMO3kdnG2ruc1qQrDSXABAHmMVGkMnpYwDiVKsvxxhbP82ix_H0LVEUh8c96PQ_O-2-FcIX_R-LOCZ9FCdY9oKuFYI4fy49F_hp2vJojV1tQlIM3Iud8ZCwOIbtaPGFiCsy_CF6r_xsjzA_MNM3NjVe1-jZRopcfb3rpRKcgnwz79LZiZg9SnwT5NXqIF',
                    statusColor: Colors.orange,
                    isWarning: true,
                  ),
                  _buildItemCard(
                    context,
                    'Salmon Fillet',
                    'Raw',
                    'Today',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDPBhTDApEe_sOQ9Aj_wuz1QTcxe8TAFn1m9cz2vmSVlXwob7aL9rAcSrvHV533f4cyOWIEpRL_z073BtuAl64I4XDU6cGBKTuRoi5V2TZTsE-wmP185joH4CjNc4nERXRQY-K77QhcuYZ0LlOBmug7_p-Tm4gQdhGPT-Bz-r8rHwpk2XVq9U72fuh45QDR7JDDQM8t1RmeG8_ig0tfZPWaILgbS8NpkJmtLDGhtxcxjAbRD-zzGG3XED1qm14JDR_TblVEyEPzaG-K',
                    statusColor: Colors.red,
                    isCritical: true,
                  ),
                  _buildItemCard(
                    context,
                    'Orange Juice',
                    'Sealed',
                    '14 days',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA-88t-HwiRfLsKPdnpgTv4V8_OgAX0qJxyI671Q4-EXDabkijEW4Pin-JoDkQB6Gy-GCdkQgscDHplpnUZhrjEeK17xE97Sqv_ZKri_gKt0VLlNm_IE-t2b0y-lc84GwH8iCqCXpTKPfXD1uoFqc24mW9TG1OlBvl_oD0cUfzYYE2Y8w628URijEROKpEPG8ZUbSaTYwIVKOuwSB9nIt2bi3uAVLK37eXlrltDPPV-WZlXhXDwptw7XFLkjd1LLUWCwNA3HW6zlhrp',
                    statusColor: const Color(0xFF13EC13),
                  ),
                  _buildItemCard(
                    context,
                    'Free Range Eggs',
                    'Dairy',
                    '8 days',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDXiczZeH3M4vqhBQQqeyRRG7_Ns1MT3Xf-Q4MLfp1SOsvkF7FbNwp3Yyzdgqt86a1iR939HIeGA_w7Tv09tqn93nURB79OrHBS6anHDGhqTC8HyRS_k1VV5_RijnN4EF0eTrAE3kkgpElsxi2Lp52GmVx5K0wRN6BLoW5WkBjVlmeA5Y84xBRcNUpRm180hKxur49gMlqDKIg52UezstHp1KLcOO2qt8J9UzTSXbNjeOG088Nt7d4h3jOuEcYWwdQrIuoLMYP48Kyv',
                    statusColor: const Color(0xFF13EC13),
                    quantity: 6,
                  ),
                  _buildItemCard(
                    context,
                    'Strawberries',
                    'Produce',
                    '1 day left',
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBTSCpqh3cU0uXdAqmx9isAMNK7stcbYHzA7pyWRQDGhOqTsKcrFfmRZLMtwYeWeuoLC_wKRiFTdPvXTF_677bCj5AI6GQXRAXqCBqrSwZBy5Lf1zEc44apDamaJm7lEwlz9YUeRHVX1nOYM7AbNd1D_xhGerAMDV_Wz7Nl_z_tnr793BesnTzGFL_dg7_ue5lwPp4fNhVjZ2tPRS0dX4w3FOBqFpm1Ngq3NUYCwo8gA0cPdJ3xGYPmrEmnBZ4Vbo7kMAfTP84S1Fnx',
                    statusColor: Colors.orange,
                  ),
                  _buildAddItemCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.scanReceipt);
        },
        backgroundColor: const Color(0xFF13EC13),
        child: const Icon(Icons.qr_code_scanner, color: Colors.black),
      ),
      bottomNavigationBar: const FridgeBottomNavigation(
        currentTab: FridgeTab.fridge,
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected, {
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {},
        backgroundColor: isWarning ? Colors.red[50] : Colors.white,
        selectedColor: const Color(0xFF13EC13),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.black
              : (isWarning ? Colors.red : Colors.grey[600]),
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF13EC13)
                : (isWarning ? Colors.red.withOpacity(0.3) : Colors.grey[300]!),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    String title,
    String subtitle,
    String expiry,
    String imageUrl, {
    Color statusColor = Colors.green,
    bool isWarning = false,
    bool isCritical = false,
    int? quantity,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.foodItemDetails);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: isCritical ? Border.all(color: Colors.red[200]!) : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  if (isCritical)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.red.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: const Text(
                          'EXPIRING TODAY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (quantity != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Qty: $quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          expiry,
                          style: TextStyle(
                            color: isCritical || isWarning
                                ? (isCritical ? Colors.red : Colors.orange)
                                : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to add item
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 32, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Item',
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
