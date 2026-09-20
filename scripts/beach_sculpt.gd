extends RefCounted
## Display-only curved surfaces. Static pieces are batched per moving joint.
const V=preload("res://scripts/visuals.gd")
static var finish: StandardMaterial3D
static func tube(parent: Node3D, points: Array[Vector3], radii: Array[float], tint: Color) -> MeshInstance3D:
	var vertices:=PackedVector3Array(); var normals:=PackedVector3Array(); var indices:=PackedInt32Array()
	for i in range(points.size()):
		var tangent: Vector3=(points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]).normalized()
		var cross:=tangent.cross(Vector3.UP if absf(tangent.y)<0.9 else Vector3.RIGHT).normalized()
		var up:=cross.cross(tangent).normalized()
		for j in range(10):
			var normal:=cross*cos(j*TAU/10)+up*sin(j*TAU/10)
			vertices.append(points[i]+normal*radii[i]); normals.append(normal)
			if i<points.size()-1:
				var a:=i*10+j; var b:=i*10+(j+1)%10
				indices.append_array(PackedInt32Array([a,b,a+10,b,b+10,a+10]))
	var arrays: Array=[]; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return V.mesh(parent,mesh,tint)
static func fin(parent: Node3D, outline: Array[Vector3], tint: Color) -> void:
	var center:=Vector3.ZERO
	for p in outline: center+=p
	center/=outline.size(); center.y+=0.07
	var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(outline.size()):
		surface.add_vertex(center); surface.add_vertex(outline[i]); surface.add_vertex(outline[(i+1)%outline.size()])
		surface.add_vertex(center-Vector3.UP*0.12); surface.add_vertex(outline[(i+1)%outline.size()]); surface.add_vertex(outline[i])
	surface.generate_normals(); V.mesh(parent,surface.commit(),tint)
	for i in range(1,outline.size()-1): V.rod(parent,tint.lightened(0.25),outline[0]+Vector3.UP*0.02,outline[i]+Vector3.UP*0.02,0.015)
static func bake(root: Node3D) -> void:
	for child in root.get_children():
		if child is Node3D and not child is MeshInstance3D: bake(child)
	var meshes: Array[MeshInstance3D]=[]
	for child in root.get_children():
		if child is MeshInstance3D: meshes.append(child)
	if meshes.is_empty(): return
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in meshes:
		var arrays:=part.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var order: PackedInt32Array=indices if not indices.is_empty() else PackedInt32Array(range(vertices.size()))
		var tint: Color=part.material_override.albedo_color
		var normal_basis:=part.transform.basis.inverse().transposed()
		for index in order:
			st.set_color(tint*arrays[Mesh.ARRAY_COLOR][index] if arrays[Mesh.ARRAY_COLOR]!=null and part.material_override.vertex_color_use_as_albedo else tint); st.set_normal((normal_basis*normals[index]).normalized()); st.add_vertex(part.transform*vertices[index])
		part.free()
	if finish==null:
		finish=StandardMaterial3D.new(); finish.vertex_color_use_as_albedo=true; finish.roughness=0.36; finish.metallic=0.08
		finish.cull_mode=BaseMaterial3D.CULL_DISABLED
	var result:=MeshInstance3D.new(); result.name="SculptedSurface"; result.mesh=st.commit(); result.material_override=finish; root.add_child(result)
