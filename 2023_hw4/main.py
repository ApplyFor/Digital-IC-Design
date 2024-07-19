import torch
from PIL import Image
import torchvision.transforms as T
import numpy as np
import torchvision.transforms.functional as F
import torch.nn as nn

# If you can, run this example on a GPU, it will be a lot faster.
device = "cuda" if torch.cuda.is_available() else "cpu"

def write(image, filename):
    dat = np.asarray(image, dtype=np.float32)
    fp = open(filename, "w")
    w, h = dat.shape
    for i in range(w):
        for j in range(h):
            number = np.uint8(dat[i][j])
            fraction = dat[i][j] - number
            fp.write("{}{} //data {}: {}\n".format(np.binary_repr(number, width=9), np.binary_repr(np.uint8(fraction*16), width=4), i*64+j, dat[i][j]))
    fp.close()

def gray_conv2D(image, kernel, bias, padding=0, strides=1, dilation=1):
    image_w, image_h = image.shape
    kernel_w, kernel_h = kernel.shape
    # print(image_w, image_h)
    # print(kernel_w, kernel_h)

    out_w = int((image_w + 2 * padding - dilation * (kernel_w - 1) - 1) / strides + 1)
    out_h = int((image_h + 2 * padding - dilation * (kernel_h - 1) - 1) / strides + 1)
    # print(out_w, out_h)
    output = np.zeros((out_w, out_h))

    for y in range(image_h):
        if y >= out_h:
            break
        if y % strides == 0:
            for x in range(image_w):
                if x >= out_w:
                    break
                if x % strides == 0:
                    # print(x, y)
                    output[x, y] = np.sum(kernel * image[x : x + dilation * kernel_w : dilation, y : y + dilation * kernel_h : dilation]) + bias
    # print(output)
    return output

if __name__ == '__main__':
    img = Image.open(r".\images\bleach.png")
    # img = Image.open(r"./image.png")
      
    gray_img = img.convert("L")
    # gray_img.show()

    resizer = T.Resize(size=[64, 64], antialias=True)
    resized_img = resizer(gray_img)
    # resized_img.show()

    write(resized_img, "img.dat")

    # Replicate padding operation
    tensor = F.pil_to_tensor(resized_img).float()
    m = nn.ReplicationPad2d(2) # pad every dim by 2 on each side
    pad = m(tensor)
    # print(pad, pad.size())

    # Atrous Convolution
    # Square kernels and equal stride and with dilation
    weight = torch.tensor([[[[-0.0625, -0.125, -0.0625],
                            [-0.25, 1., -0.25],
                            [-0.0625, -0.125, -0.0625]]]])
    bias = torch.tensor([-0.75])
    conv = nn.functional.conv2d(pad.unsqueeze(0), weight, bias, stride=1, dilation=2)

    # kernel = np.array([[-0.0625, -0.125, -0.0625],
    #                     [-0.25, 1., -0.25],
    #                     [-0.0625, -0.125, -0.0625]])
    # bias = -0.75
    # conv = gray_conv2D(np.asarray(pad.squeeze(0)), kernel, bias, strides=1, dilation=2)
    # print(conv, conv.size())

    # ReLU Function
    relu = nn.functional.relu(conv)
    # print(relu, relu.size())

    layer0 = F.to_pil_image(relu.squeeze(0).to(device), "F")
    # layer0.show()

    write(layer0, "layer0_golden.dat")

    # Max-pooling
    maxpool = nn.functional.max_pool2d(relu, 2, stride=2)
    # print(maxpool, maxpool.size())

    # Round up
    ceiling = torch.ceil(maxpool.squeeze(0))
    print(ceiling, ceiling.size())

    layer1 = F.to_pil_image(ceiling.to(device), "F")
    # layer1.show()

    write(layer1, "layer1_golden.dat")
