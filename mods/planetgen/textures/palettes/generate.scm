; This is a Script-Fu GIMP script
; Copy it into your '~/.config/GIMP/<version>/scripts/' directory
; Then, use it from GIMP as File -> Create -> Planetgen Palette Atlas
; It will create all palettes automatically as a single image
; Finally, export the atlas to this directory as 'atlas.png'
; See 'split.sh' for following steps

(define (exp2 z)
    (inexact->exact(round(exp (* z (log 2)))))
)

(define (fnExtractBits n lower num)
    (remainder (quotient n (exp2 lower)) (exp2 num))
)

(define (fnBitsDistribution n lower num max)
    (round (* (/ (fnExtractBits n lower num) (- (exp2 num) 1)) max))
)

(define (fnLighten n m)
    (- 255 (floor (/ (- 255 n) m)))
)

(define (fnColorWaterRandom n)
    (let*
        (
            (theR (fnBitsDistribution n 0 2 255))
            (theG (fnBitsDistribution n 2 2 255))
            (theB (fnBitsDistribution n 4 1 255))
        )
        (vector (fnLighten theR 2) (fnLighten theG 2) (fnLighten theB 2))
    )
)

(define (fnColorWaterNormal n)
    (let*
        (
            (theR (fnBitsDistribution n 0 1 64))
            (theG (fnBitsDistribution n 1 2 192))
            (theB 255)
        )
        (vector (fnLighten theR 2) (fnLighten theG 2) (fnLighten theB 2))
    )
)

(define (fnColorGrassRandom n)
    (let*
        (
            (theR (fnBitsDistribution n 0 2 255))
            (theG (fnBitsDistribution n 2 2 255))
            (theB (fnBitsDistribution n 4 1 255))
        )
        (vector (fnLighten theR 1.7) (fnLighten theG 1.7) (fnLighten theB 1.7))
    )
)

(define (fnColorGrassNormal n)
    (let*
        (
            (theG (+ 128 (fnBitsDistribution n 0 1 127)))
            (theR (fnBitsDistribution n 1 2 theG))
            (theB (fnBitsDistribution n 3 1 (- theG 64)))
        )
        (vector (fnLighten theR 1.7) (fnLighten theG 1.7) (fnLighten theB 1.7))
    )
)

(define (doFillVariantsRecursive inLayer inStart inCurrent inEnd inFunction)
    (if (>= inCurrent inEnd)
        '()
        (let* () ;local variables
            (let*
                (
                    (theX (remainder inCurrent 8))
                    (theY (quotient inCurrent 8))
                )
                (gimp-drawable-set-pixel inLayer theX theY 3 (inFunction inCurrent))
            )
            (doFillVariantsRecursive inLayer inStart (+ inCurrent 1) inEnd inFunction)
        )
    )
)

(define (doFillVariants inLayer inRow inCount inFunction)
    (let*
        (
            (theStart (* inRow 8))
            (theEnd (+ theStart (* inCount 8)))
        ) ;local variables
        (doFillVariantsRecursive inLayer theStart theStart theEnd inFunction)
    )
)

(define (script-fu-planetgen-palette-atlas)
    (let*
        (
            (theImageWidth  8)
            (theImageHeight 10)
            (theImage (car (gimp-image-new
                 theImageWidth
                 theImageHeight
                 RGB
            )))
            (theLayer (car (gimp-layer-new
               theImage
               theImageWidth
               theImageHeight
               RGB-IMAGE
               "layer 1"
               100
               LAYER-MODE-NORMAL
            )))
        ) ;local variables

        (gimp-image-add-layer theImage theLayer 0)

        (doFillVariants theLayer 0 3 fnColorWaterRandom)
        (doFillVariants theLayer 3 1 fnColorWaterNormal)
        (doFillVariants theLayer 4 4 fnColorGrassRandom)
        (doFillVariants theLayer 8 2 fnColorGrassNormal)

        (gimp-display-new theImage)
        (gimp-image-clean-all theImage)
    )
)

(script-fu-register
    "script-fu-planetgen-palette-atlas"         ;func name
    "Planetgen Palette Atlas"                   ;menu label
    "Creates palette atlas for the Minetest\
    mod Planetgen."                             ;description
    "Aritz Erkiaga"                             ;author
    "copyright 2021, Aritz Erkiaga"             ;copyright notice
    "August 22, 2021"                           ;date created
    ""                     ;image type that the script works on
)
(script-fu-menu-register "script-fu-planetgen-palette-atlas" "<Image>/File/Create")
