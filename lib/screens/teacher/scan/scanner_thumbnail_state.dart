part of 'scanner_thumbnail.dart';

/** Releases displayed handles on memory pressure, replacement and disposal. */
class _ScannerThumbnailState extends State<ScannerThumbnail> {
  ui.Image? _image;
  int _request = 0;
  late int _generation;

  /** Subscribes to the session cache before reading the preview. */
  @override
  void initState() {
    super.initState();
    _generation = widget.cache.generation;
    widget.cache.addListener(_changed);
    _load();
  }

  /** Switches the cache subscription if this preview is reused. */
  @override
  void didUpdateWidget(ScannerThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cache != widget.cache) {
      oldWidget.cache.removeListener(_changed);
      widget.cache.addListener(_changed);
      _generation = widget.cache.generation;
    }
    if (oldWidget.path != widget.path ||
        oldWidget.cache != widget.cache ||
        _image == null) {
      _load();
    }
  }

  /** Discards old handles and reloads only after a resume signal. */
  void _changed() {
    if (!mounted) return;
    if (_generation != widget.cache.generation) {
      _generation = widget.cache.generation;
      _request++;
      setState(() {
        _image?.dispose();
        _image = null;
      });
    } else if (!widget.cache.suspended && _image == null) {
      _load();
    }
  }

  /** Ignores a result when its page or scan has changed. */
  Future<void> _load() async {
    final request = ++_request;
    final image = await widget.cache.get(widget.path);
    if (!mounted || request != _request) {
      image?.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  /** Releases this widget's clone without disposing the cached image. */
  @override
  void dispose() {
    _request++;
    widget.cache.removeListener(_changed);
    _image?.dispose();
    super.dispose();
  }

  /** Keeps a fixed placeholder while loading or when a photo cannot be read. */
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 64,
      child: _image == null
          ? const Icon(Icons.description_outlined)
          : RawImage(image: _image, fit: BoxFit.cover),
    );
  }
}
