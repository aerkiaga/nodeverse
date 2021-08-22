; This is a Script-Fu GIMP script
; Copy it into your '~/.config/GIMP/<version>/scripts/' directory
; Then, use it from GIMP as File -> Create -> Planetgen Palette Atlas
; It will create all palettes automatically as a single image
; Finally, export the atlas to this directory as 'atlas.png'
; See 'split.sh' for following steps

(define (script-fu-planetgen-palette-atlas)
    (let*
        (
            (theImageWidth  8)
            (theImageHeight 4)
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
        ) ;end of our local variables

        (gimp-image-add-layer theImage theLayer 0)
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
