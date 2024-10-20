import MetalKit
import SwiftUI

struct MetalView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.delegate = context.coordinator
        return metalView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?

        let vertices: [Float] = [
            // Position (x, y, z), Color (r, g, b)
             0.0,  1.0, 0.0,  1.0, 0.0, 0.0,  // Top vertex (red)
            -1.0, -1.0, 0.0,  0.0, 1.0, 0.0,  // Bottom-left vertex (green)
             1.0, -1.0, 0.0,  0.0, 0.0, 1.0   // Bottom-right vertex (blue)
        ]
        var vertexBuffer: MTLBuffer?

        init(_ parent: MetalView) {
            self.parent = parent
            if let device = MTLCreateSystemDefaultDevice() {
                self.commandQueue = device.makeCommandQueue()

                // Create the vertex buffer
                self.vertexBuffer = device.makeBuffer(bytes: vertices,
                                                      length: vertices.count * MemoryLayout<Float>.size,
                                                      options: [])

                // Create a vertex descriptor
                let vertexDescriptor = MTLVertexDescriptor()
                vertexDescriptor.attributes[0].format = .float3    // Position (x, y, z)
                vertexDescriptor.attributes[0].offset = 0
                vertexDescriptor.attributes[0].bufferIndex = 0

                vertexDescriptor.attributes[1].format = .float3    // Color (r, g, b)
                vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3
                vertexDescriptor.attributes[1].bufferIndex = 0

                vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 6
                vertexDescriptor.layouts[0].stepFunction = .perVertex

                // Create a pipeline state to render the triangle
                let library = device.makeDefaultLibrary()
                let pipelineDescriptor = MTLRenderPipelineDescriptor()
                pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
                pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_main")
                pipelineDescriptor.vertexDescriptor = vertexDescriptor
                pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

                do {
                    self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                } catch {
                    fatalError("Unable to create pipeline state: \(error)")
                }
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let commandQueue = commandQueue,
                  let pipelineState = pipelineState else {
                return
            }

            let commandBuffer = commandQueue.makeCommandBuffer()
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

            renderEncoder?.setRenderPipelineState(pipelineState)
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

            renderEncoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}
