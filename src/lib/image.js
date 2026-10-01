// Shrink a photo ON THE PHONE before uploading it.
// A phone photo is 3–5 MB; a recipe photo only needs to look good on a phone screen.
// We draw it smaller onto a canvas and save it as a JPEG, aiming for about 200 KB.

const MAX_SIDE = 1280 // longest side, in pixels
const TARGET_BYTES = 250 * 1024
const QUALITIES = [0.82, 0.72, 0.62, 0.5] // try lower quality until it's small enough

// canvas.toBlob uses a callback; wrap it in a Promise so we can `await` it.
const canvasToBlob = (canvas, quality) =>
  new Promise((resolve, reject) =>
    canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error('Could not process the photo.'))), 'image/jpeg', quality),
  )

export async function shrinkImage(file) {
  let bitmap
  try {
    // imageOrientation: 'from-image' respects the phone's rotation info, so photos aren't sideways.
    bitmap = await createImageBitmap(file, { imageOrientation: 'from-image' })
  } catch {
    throw new Error('That file couldn’t be read as a photo. Try a JPEG or PNG.')
  }

  const scale = Math.min(1, MAX_SIDE / Math.max(bitmap.width, bitmap.height))
  const width = Math.round(bitmap.width * scale)
  const height = Math.round(bitmap.height * scale)

  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  canvas.getContext('2d').drawImage(bitmap, 0, 0, width, height)
  bitmap.close()

  let blob
  for (const quality of QUALITIES) {
    blob = await canvasToBlob(canvas, quality)
    if (blob.size <= TARGET_BYTES) break
  }
  return blob
}
