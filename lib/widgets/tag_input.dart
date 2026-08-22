import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// [ChipTagInput]'un dışarıdan okunabilmesi/sıfırlanabilmesi için basit controller.
class TagInputController extends ChangeNotifier {
  final List<String> tags = [];
  final TextEditingController textController = TextEditingController();

  void commitPending() {
    final val = textController.text.trim();
    if (val.isNotEmpty) {
      tags.add(val);
      textController.clear();
      notifyListeners();
    }
  }

  void removeAt(int i) {
    tags.removeAt(i);
    notifyListeners();
  }

  void reset() {
    tags.clear();
    textController.clear();
    notifyListeners();
  }

  /// Etiketleri " / " ile birleştirir — defterdeki gibi tek satır
  String get joined => tags.join(' / ');

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}

/// Her işlemden sonra Enter'a basıldığında yazılan metni turuncu bir etikete
/// dönüştüren girdi alanı. Kutuya dokunulduğunda küçük bir ipucu belirir,
/// ilk etiket eklendiğinde ipucu kalıcı olarak kaybolur. Etiketler ayrıca
/// üzerlerindeki × ile tek tek silinebilir.
class ChipTagInput extends StatefulWidget {
  final TagInputController controller;
  const ChipTagInput({super.key, required this.controller});

  @override
  State<ChipTagInput> createState() => _ChipTagInputState();
}

class _ChipTagInputState extends State<ChipTagInput> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
      if (!_focusNode.hasFocus) {
        widget.controller.commitPending();
      }
    });
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmitted(String _) {
    widget.controller.commitPending();
    // Klavyeyi kapatmadan bir sonraki kaleme geçmek için odağı koru
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final showHint = _hasFocus && widget.controller.tags.isEmpty;
    final hasTags = widget.controller.tags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(_focusNode),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgElev2,
              border: Border.all(
                color: _hasFocus ? AppColors.orangeDim : AppColors.line,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < widget.controller.tags.length; i++)
                  _TagChip(
                    text: widget.controller.tags[i],
                    onRemove: () => widget.controller.removeAt(i),
                  ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: widget.controller.textController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _onSubmitted,
                    inputFormatters: [TitleCaseInputFormatter()],
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                    cursorColor: AppColors.orange,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hasTags
                          ? 'Ekle...'
                          : "Her işlemden sonra Enter'a bas... Örneğin: Hava filt ↩️ Fren balata ↩️",
                      hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showHint)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                children: [
                  TextSpan(text: 'Her kalemi yazdıktan sonra '),
                  TextSpan(
                    text: "Enter'a",
                    style: TextStyle(color: AppColors.orange),
                  ),
                  TextSpan(text: ' basarak ekle'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final VoidCallback onRemove;
  const _TagChip({required this.text, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 13, right: 8, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.orangeGlow,
        border: Border.all(color: AppColors.orangeDim),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 15, color: AppColors.orange),
          ),
        ],
      ),
    );
  }
}
