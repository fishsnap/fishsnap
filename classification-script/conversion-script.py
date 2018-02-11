import coremltools

caffe_model = ('snapshot_iter_450.caffemodel', 'deploy.prototxt')
labels = 'fish-labels.txt'

coreml_model = coremltools.converters.caffe.convert(
    caffe_model,
    class_labels=labels,
    image_input_names='data'
)

coreml_model.save('FishClassifier.mlmodel')
