package main

import (
	"os"
	"fmt"
	"image"
	"image/jpeg"
    "math"
    "time"
    "interp"
)

/**
 * 计算向量的长度
 * @param  {[type]} val [3]float64  [description]
 * @return {float64}     向量长度
 */
func length(val [3]float64) (float64){
    return math.Sqrt(val[0] * val[0] + val[1] * val[1] + val[2] * val[2])
}

/**
 * 向量除以常数计算
 * @param  {[type]} val [3]float64    [description]
 * @param  {[type]} d   float64       [description]
 * @return {[3]float64}
 */
func div(val [3]float64, d float64) ([3]float64) {
    return [3]float64{val[0] / d, val[1] / d, val[2] / d}
}

/**
 * 计算生成向量对应的单位向量
 * @param  {[type]} val [3]float64  [description]
 * @return {[3]float64}     单位向量
 */
func norm(val [3]float64) ([3]float64){
    return div(val, length(val))
}

/**
 * 向量相加计算
 * @param  {[type]} val [3]float64  [description]
 * @param  {[type]} vec [3]float64  [description]
 * @return {[3]float64}
 */
func add(val [3]float64, vec [3]float64) ([3]float64){
    return [3]float64{val[0] + vec[0], val[1] + vec[1], val[2] + vec[2]}
}

/**
 * 向量乘以数字计算
 * @param  {[type]} val [3]float64    [description]
 * @param  {[type]} d   float64       [description]
 * @return {float64}
 */
func mul(val [3]float64, d float64) ([3]float64) {
    return [3]float64{val[0] * d, val[1] * d, val[2] * d}
}

/**
 * 三位坐标转换成极坐标
 * @param {[type]} x float64  [description]
 * @param {[type]} y float64  [description]
 * @param {[type]} z float64) 
 * @return (hRad float64, vRad float64)
 */
func XYZToHVRad(x float64, y float64, z float64) (hRad float64, vRad float64){
    t := math.Sqrt( x * x + y * y)

    hRad = 0.0
    if t > 0.0 {
        cosh := x / t
        hRad = math.Acos(cosh)
        if y < 0.0 {
            hRad = 2.0 * math.Pi - hRad
        }
    }
    d := math.Sqrt(t*t + z*z)
    sint := z / d
    vRad = math.Asin(sint)

    return hRad, vRad
}

/**
 * 计算生成单张六面图的坐标映射数组
 * @param  {[type]} origin      [3]float64    [description]
 * @param  {[type]} wVec        [3]float64    [description]
 * @param  {[type]} hVec        [3]float64    [description]
 * @param  {[type]} imageWidth  int           [description]
 * @param  {[type]} imageHeight int           [description]
 * @param  {[type]} width       int           [description]
 * @param  {[type]} height      int)          (result       [][2]int [description]
 * @return {[type]}             [description]
 */
func calculatePosition(origin [3]float64, wVec [3]float64, hVec [3]float64, imageWidth int, imageHeight int, width int, height int) (result [][2]float64){
    wFace := length(wVec)
    hFace := length(hVec)
    wPixel := wFace / float64(width)
    hPixel := hFace / float64(height)

    wSubPixel := wPixel / 1.0
    hSubPixel := hPixel / 1.0

    wDir := norm(wVec)
    hDir := norm(hVec)

    var dy [3]float64
    var basePos [3]float64
    var dx [3]float64
    var pos [3]float64
    var dySubPixel [3]float64
    var baseSubPos [3]float64
    var dxSubPixel [3]float64
    var subPos [3]float64

    result = [][2]float64{}

    for py := 0; py < height; py++ {
        dy = mul(hDir, float64(py) * hPixel)
        basePos = add(origin, dy)
        for px := 0; px < width; px++ {
            dx = mul(wDir, float64(px) * wPixel)
            pos = add(basePos, dx)

            dySubPixel = mul(hDir, 0.5 * hSubPixel)
            baseSubPos = add(pos, dySubPixel)

            dxSubPixel = mul(wDir, 0.5 * wSubPixel)
            subPos = add(baseSubPos, dxSubPixel)

            hRad, vRad := XYZToHVRad(subPos[0], subPos[1], subPos[2])

            x := hRad * float64(imageWidth) / (math.Pi * 2.0)
            y := (vRad + math.Pi * 0.5) * float64(imageHeight) / math.Pi
            y = float64(imageHeight) - y

            result = append(result, [2]float64{x, y})
        }
    }

    return result
}

/**
 * 通过坐标映射数组以及原始图像，生成指定名称的六面图片
 * @param  {[type]} img       image.Image   图像对象
 * @param  {[type]} positions [][2]int      坐标映射数组
 * @param  {[type]} width     int           生成图片等宽
 * @param  {[type]} height    int           生成图片的高
 * @param  {[type]} path      string        生成图片保存位置
 * @return error
 */
func positionToImage(img image.Image, positions [][2]float64, width int, height int, path string) (err error) {
    rgba := image.NewRGBA(image.Rect(0, 0, width, height))
    for i := 0; i < len(positions); i++ {
        h := int(math.Floor(float64(i) / float64(width)))
        w := i - h * width
        color := interp.BilinearGeneral(img, positions[i][0], positions[i][1]);
        // color := img.At(positions[i][0], positions[i][1])
        rgba.Set(w, h, color)
    }
    newFile, _ := os.Create(path)
    defer newFile.Close()
    err = jpeg.Encode(newFile, rgba, &jpeg.Options{85})
    return err
}

// 入口主函数
func main() {
    layout := "01-02-2006 3.04.05 PM"
    fmt.Println(time.Now().Format(layout))

	file := "pano1.jpg"
	fimigfile, _ := os.Open(file)
    defer fimigfile.Close()
    img, _, err := image.Decode(fimigfile)
    if err != nil {
    	fmt.Printf("Decode image failed.")
    }else{
        bound := img.Bounds()
        imageWidth := bound.Max.X - bound.Min.X
        imageHeight := bound.Max.Y - bound.Min.Y
    	width := int(math.Ceil(float64(imageWidth) / math.Pi))
    	height := width
        fmt.Println(width)

        front := calculatePosition([3]float64{-1.0, 1.0, 1.0}, [3]float64{0.0, -2.0, 0.0}, [3]float64{0.0, 0.0, -2.0}, imageWidth, imageHeight, width, height)
        err = positionToImage(img, front, width, height, "pano_f.jpg")

        left := calculatePosition([3]float64{1.0, 1.0, 1.0}, [3]float64{-2.0, 0.0, 0.0}, [3]float64{0.0, 0.0, -2.0}, imageWidth, imageHeight, width, height)
        err = positionToImage(img, left, width, height, "pano_l.jpg")

        right := calculatePosition([3]float64{-1.0, -1.0, 1.0}, [3]float64{2.0, 0.0, 0.0}, [3]float64{0.0, 0.0, -2.0}, imageWidth, imageHeight, width, height)
        err = positionToImage(img, right, width, height, "pano_r.jpg")

        back := calculatePosition([3]float64{1.0, -1.0, 1.0}, [3]float64{0.0, 2.0, 0.0}, [3]float64{0.0, 0.0, -2.0}, imageWidth, imageHeight, width, height)
        err = positionToImage(img, back, width, height, "pano_b.jpg")

        up := calculatePosition([3]float64{1.0, 1.0, 1.0}, [3]float64{0.0, -2.0, 0.0}, [3]float64{2.0, 0.0, 0.0}, imageWidth, imageHeight, width, height)
        err = positionToImage(img, up, width, height, "pano_u.jpg")

        down := calculatePosition([3]float64{-1.0, 1.0, -1.0}, [3]float64{0.0, -2.0, 0.0}, [3]float64{2.0, 0.0, 0.0}, imageWidth, imageHeight, width, height)
        err = positionToImage(img, down, width, height, "pano_d.jpg")
    }

    fmt.Println(time.Now().Format(layout))
}