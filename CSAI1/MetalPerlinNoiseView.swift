//
//  MetalPerlinNoiseView.swift
//  CSAI1
//
//  Created by DM on 3/25/25.
//  Updated on 4/02/25
//

import SwiftUI
import MetalKit

struct MetalPerlinNoiseView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.backgroundColor = .clear
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // Create and assign the renderer
        let renderer = Renderer(mtkView: mtkView)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer
        
        // Set the desired frame rate
        mtkView.preferredFramesPerSecond = 30
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // No dynamic updates required
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var renderer: Renderer?
    }
}

class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!
    private var startTime: CFTimeInterval = CACurrentMediaTime()
    
    struct Uniforms {
        var time: Float
        var resolution: SIMD2<Float>
    }
    
    init(mtkView: MTKView) {
        guard let device = mtkView.device else {
            fatalError("No Metal device available.")
        }
        self.device = device
        guard let queue = device.makeCommandQueue() else {
            fatalError("Could not create command queue.")
        }
        self.commandQueue = queue
        super.init()
        buildPipelineState(mtkView: mtkView)
    }
    
    private func buildPipelineState(mtkView: MTKView) {
        // Load the default Metal library
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not create default Metal library.")
        }
        guard let vertexFunction = library.makeFunction(name: "v_main"),
              let fragmentFunction = library.makeFunction(name: "f_main") else {
            fatalError("Could not find shader functions 'v_main' and 'f_main'.")
        }
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes if needed
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }
        
        // Calculate elapsed time
        let currentTime = CACurrentMediaTime()
        let elapsed = Float(currentTime - startTime)
        
        // Prepare uniforms for shaders
        var uniforms = Uniforms(
            time: elapsed,
            resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
        )
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
        
        // Draw a full-screen triangle
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
