// lib/screens/service_call/service_call_validation/components/widgets/service_call_validation_widgets.dart
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../../models/service_call/problem_source_model.dart';
import '../../../../../models/common/captured_image_detail.dart';

class HeaderInfo extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String lineNo;
  final String complaintDetails;
  final String imageFile;

  const HeaderInfo({
    super.key,
    required this.transNo,
    required this.serialNo,
    required this.lineNo,
    required this.complaintDetails,
    required this.imageFile,
  });

  @override
  State<HeaderInfo> createState() => _HeaderInfoState();
}

class _HeaderInfoState extends State<HeaderInfo> {
  bool isImageLoaded = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: widget.imageFile.isEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    body: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: Hero(
                          tag: widget.imageFile,
                          child: InteractiveViewer(
                            child: Image.network(widget.imageFile),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
      child: widget.imageFile.isEmpty
          ? SizedBox(
              height: screenHeight * 0.25,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey.shade300,
                    child:
                        const Icon(Icons.image, size: 60, color: Colors.grey),
                  ),
                  _buildOverlayContent(),
                ],
              ),
            )
          : Hero(
              tag: widget.imageFile,
              child: SizedBox(
                height: screenHeight * 0.25,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.imageFile,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null && !isImageLoaded) {
                          Future.microtask(() {
                            if (mounted) {
                              setState(() {
                                isImageLoaded = true;
                              });
                            }
                          });
                        }
                        return isImageLoaded
                            ? child
                            : Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(color: Colors.grey),
                              );
                      },
                      errorBuilder: (context, error, _) => Container(
                        color: Colors.grey.shade400,
                        child: const Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                    _buildOverlayContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverlayContent() {
    return Container(
      color: Colors.black.withOpacity(0.45),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.transNo,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 4),
          Text(widget.serialNo, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text("Masalah: ${widget.complaintDetails}",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

Widget buildUnitTypeSelector({
  required BuildContext context,
  required String? groupValue, // Terima nilai yang dipilih
  required ValueChanged<String?> onChanged, // Terima callback
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        color: Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: const Text(
          'Pilih Sumber Permasalahan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: ['UNIT', 'NON_UNIT'].map((unitType) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(unitType, style: const TextStyle(fontSize: 14)),
                value: unitType,
                groupValue: groupValue, // Gunakan parameter
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: onChanged, // Gunakan parameter
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

Widget buildProblemCards({
  required BuildContext context,
  required ValidationDropdownLoaded state,
  required List<Problem> problemsForType,
  Widget? buttonAdd,
}) {
  final List<SelectedProblemCard> problemCards = state.selectedProblemCards;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      if (problemCards.isNotEmpty)
        ...problemCards.map((card) {
          final selectedProblem = problemsForType.firstWhereOrNull(
            (p) => p.causeId == card.selectedProblemId,
          );

          final selectedSolutions = selectedProblem?.solutions
                  .where((s) => card.selectedSolutionIds.contains(s.solutionId))
                  .toList() ??
              [];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: buildProblemCard(
              context: context,
              card: card,
              selectedProblem: selectedProblem,
              selectedSolutions: selectedSolutions,
              onRemove: () {
                if (card.selectedProblemId != null) {
                  context.read<ValidationDropdownBloc>().add(
                        RemoveProblemCard(problemId: card.selectedProblemId!),
                      );
                }
              },
            ),
          );
        })
      else
        buttonAdd == null ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '[ Tambahkan Permasalahan Yang Ditemukan ]',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ) : const SizedBox.shrink(),
      buttonAdd ?? const SizedBox.shrink(),
    ],
  );
}

Widget buildProblemCard({
  required BuildContext context,
  required SelectedProblemCard card,
  required Problem? selectedProblem,
  required List<Solution> selectedSolutions,
  required void Function() onRemove,
}) {
  return Dismissible(
    key: ValueKey(card.selectedProblemId ?? UniqueKey()),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      color: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (_) async {
      return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Hapus Permasalahan'),
              content: const Text('Yakin ingin menghapus permasalahan ini?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;
    },
    onDismissed: (_) => onRemove(),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedProblem?.causeName ?? '[ Permasalahan tidak ditemukan ]',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Solusi:",
              style: TextStyle(fontSize: 16),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedSolutions
                  .map((s) => Chip(
                        label: Text(s.solutionName),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildPhotoSection(BuildContext context, ValidationDropdownLoaded state,
    {required bool isBefore, required bool isLoading}) {
  final List<CapturedImageDetail> photos =
      isBefore ? state.capturedPhotosBefore : state.capturedPhotosAfter;
  String title =
      isBefore ? 'Foto Unit Sebelum Servis' : 'Foto Unit Sesudah Servis';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        color: Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      if (photos.isNotEmpty) // MODIFIKASI: Gunakan list 'photos'
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: buildPhotoGrid(context, photos,
              isBefore: isBefore, isLoading: isLoading), // MODIFIKASI: Teruskan list 'photos'
        )
      else if (photos.isEmpty && isLoading)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: buildPhotoGrid(context, photos,
              isBefore: isBefore,
              isLoading: isLoading), // MODIFIKASI: Teruskan list 'photos'
        )
      else
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '[ Tambahkan $title ]',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
    ],
  );
}

Widget buildPhotoGrid(BuildContext context, List<CapturedImageDetail> photos, {required bool isBefore, required bool isLoading}) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),

    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,    // Jumlah kolom yang diinginkan (bisa diubah misal: 3 atau 5)
      crossAxisSpacing: 8,  // Jarak antar item secara horizontal
      mainAxisSpacing: 8,   // Jarak antar item secara vertikal
    ),

    // Jumlah total item di dalam grid
    itemCount: photos.length + (isLoading ? 1 : 0), // Tambah 1 jika sedang loading

    // Builder untuk membuat setiap item
    itemBuilder: (context, index) {
      // Jika ini adalah item terakhir DAN sedang loading, tampilkan placeholder
      if (isLoading && index == photos.length) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      // Jika bukan, tampilkan thumbnail foto
      final imageDetail = photos[index];
      return Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(
                    imageDetail:
                    imageDetail), // MODIFIKASI: Gunakan FullScreenImageViewer
              ),
            ),
            child: Hero(
              tag: imageDetail.imagePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FadeInImage(
                  placeholder: const AssetImage(
                      'assets/images/placeholder_image.jpeg'),
                  // Gambar placeholder
                  image: FileImage(File(imageDetail.imagePath)),
                  // Gambar asli
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  // Jika terjadi error saat load gambar asli
                  imageErrorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image,
                        size: 40, color: Colors.grey);
                  },
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (isBefore) {
                context
                    .read<ValidationDropdownBloc>()
                    .add(RemoveCapturedPhotoBefore(imageDetail.imagePath));
              } else {
                context
                    .read<ValidationDropdownBloc>()
                    .add(RemoveCapturedPhotoAfter(imageDetail.imagePath));
              }
            },
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ],
      );
    },
  );
}

class ServiceCallValidationActionButtons extends StatelessWidget {
  final void Function(BuildContext, ValidationDropdownLoaded) onPhoto;
  final void Function(BuildContext)? onAddProblem;
  final void Function(BuildContext, ValidationDropdownLoaded, String, String)?
      onSave;
  final ValidationDropdownLoaded state;
  final String transNo;
  final String serialNo;
  final bool isBefore;

  const ServiceCallValidationActionButtons({
    super.key,
    required this.onPhoto,
    this.onAddProblem,
    this.onSave,
    required this.state,
    required this.transNo,
    required this.serialNo,
    required this.isBefore,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBefore) {
      if (state.selectedUnitType == null) return const SizedBox.shrink();
    }

    final bool showSaveButton = !isBefore;
    final bool showAddProblemButton = !isBefore;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: Row(
          children: [
            // 📸 FOTO
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => onPhoto(context, state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(),
                  elevation: 2,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: SizedBox(
                  height: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      SizedBox(height: 2),
                      Text("Foto",
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

            // ➕ PERMASALAHAN
            // MODIFIKASI START: Tampilkan hanya jika showAddProblemButton true
            if (showAddProblemButton)
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: onAddProblem != null
                      ? () => onAddProblem!(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: SizedBox(
                    height: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(height: 2),
                        Text("Masalah",
                            style:
                                TextStyle(fontSize: 10, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            // MODIFIKASI END

            // 💾 SIMPAN
            // MODIFIKASI START: Tampilkan hanya jika showSaveButton true
            if (showSaveButton)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onSave != null
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Konfirmasi Simpan'),
                              content: const Text(
                                  'Apakah Anda yakin ingin menyimpan data ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Ya, Simpan'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            onSave!(context, state, transNo, serialNo);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.save, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text("Simpan",
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            // MODIFIKASI END
          ],
        ),
      ),
    );
  }
}

Future<void> showDialogAddProblem({
  required BuildContext context,
  required List<Problem> problems,
  required List<String> existingProblemIds,
  required Function(String problemId, List<String> solutionIds) onAdd,
}) async {
  String? selectedProblemId;
  List<String> selectedSolutionIds = [];
  String? selectedSolutionId;

  List<Solution> getAvailableSolutions() {
    final selectedProblem = problems.firstWhere(
      (p) => p.causeId == selectedProblemId,
      orElse: () => Problem(causeId: '', causeName: '', solutions: []),
    );
    return selectedProblem.solutions
        .where((s) => !selectedSolutionIds.contains(s.solutionId))
        .toList();
  }

  bool isDuplicateProblem() {
    return selectedProblemId != null &&
        existingProblemIds.contains(selectedProblemId);
  }

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Tambah Permasalahan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Permasalahan'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedProblemId,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Pilih Permasalahan'),
                      items: problems
                          .map((p) => DropdownMenuItem<String>(
                                value: p.causeId,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    p.causeName,
                                    style: const TextStyle(fontSize: 14),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProblemId = value;
                          selectedSolutionIds.clear();
                          selectedSolutionId = null;
                        });
                      },
                    ),
                    if (isDuplicateProblem())
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Permasalahan ini sudah dipilih.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text('Solusi'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedSolutionIds.length),
                      isExpanded: true,
                      value: null,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Pilih solusi'),
                      items: getAvailableSolutions()
                          .map((s) => DropdownMenuItem(
                                value: s.solutionId,
                                child: Text(
                                  s.solutionName,
                                  style: const TextStyle(fontSize: 13),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  maxLines: 2,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null &&
                            !selectedSolutionIds.contains(value)) {
                          setState(() {
                            selectedSolutionIds.add(value);
                            // Tidak perlu set selectedSolutionId
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedSolutionIds.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedSolutionIds.map((solutionId) {
                          final solutionName = problems
                              .expand((p) => p.solutions)
                              .firstWhere(
                                (s) => s.solutionId == solutionId,
                                orElse: () => Solution(
                                    solutionId: '',
                                    solutionName: '',
                                    ahoFlag: ''),
                              )
                              .solutionName;
                          return Chip(
                            label: Text(
                              solutionName,
                              style: const TextStyle(fontSize: 12),
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            onDeleted: () {
                              setState(() {
                                selectedSolutionIds.remove(solutionId);
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: selectedProblemId != null &&
                        selectedSolutionIds.isNotEmpty &&
                        !isDuplicateProblem()
                    ? () {
                        onAdd(selectedProblemId!, selectedSolutionIds);
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Tambah'),
              ),
            ],
          );
        },
      );
    },
  );
}
