"""pyanjay build script"""

import pathlib
from setuptools import setup, Extension, find_packages

with open('README.rst') as readme_file:
    long_description = readme_file.read()

# The package can't be imported at this point since the extension
# module does not exist yet. Therefore, we grab the metadata lines
# manually.
with open('pyanjay/__init__.py') as init:
    lines = [line for line in init.readlines() if line.startswith('__')]
exec(''.join(lines), globals())

anjay_static = [
    '/usr/local/lib/libanjay.a',
    '/usr/local/lib/libavs_coap.a',
    '/usr/local/lib/libavs_algorithm.a',
    '/usr/local/lib/libavs_net_mbedtls.a',
    '/usr/local/lib/libavs_crypto_mbedtls.a',
    '/usr/local/lib/libavs_sched.a',
    '/usr/local/lib/libavs_stream_net.a',
    '/usr/local/lib/libavs_persistence.a',
    '/usr/local/lib/libavs_rbtree.a',
    '/usr/local/lib/libavs_stream.a',
    '/usr/local/lib/libavs_buffer.a',
    '/usr/local/lib/libavs_list.a',
    '/usr/local/lib/libavs_utils.a',
    '/usr/local/lib/libavs_compat_threading_atomic_spinlock.a',
    '/usr/local/lib/libavs_log.a',
    '/usr/local/lib/libavs_list.a',
    '/usr/local/lib/libavs_utils.a',
    '/usr/local/lib/libavs_compat_threading_atomic_spinlock.a',
    '/usr/local/lib/libavs_log.a'
]

anjaylibs = [
    'mbedtls',
    'mbedx509',
    'mbedcrypto'
]

srcdir = pathlib.Path('src')
srcfiles = [str(srcdir /f.name) for f in srcdir.glob('*.c')]
ext_modules = [
    Extension(
        'pyanjay.anjay',
        sources=['pyanjay/anjay.pyx'] + srcfiles,
        library_dirs=['/usr/lib/x86_64-linux-gnu/'],
        libraries=anjaylibs,
        include_dirs=['include', '/usr/local/include/'],
        extra_objects=anjay_static,
    ),
    Extension(
        'pyanjay.dm',
        sources=['pyanjay/dm.pyx'],
        library_dirs=['/usr/lib/x86_64-linux-gnu/'],
        libraries=anjaylibs,
        include_dirs=['include', '/usr/local/include/'],
        extra_objects=anjay_static,
    )
]
for e in ext_modules:
    e.cython_directives = {'language_level': "3"}

setup(
    name='pyanjay',
    version=__version__,
    author=__author__,
    author_email=__email__,
    description='Python binding for Anjay LwM2M library',
    long_description=long_description,
    license=__license__,
    keywords='lwm2m anjay',
    url=__url__,
    ext_modules=ext_modules,
    packages=find_packages(),
    include_package_data=True,
    setup_requires=[
        'setuptools>=18.0',
        'cython'
    ],
    test_suite="test",
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: MIT License',
        'Natural Language :: English',
        'Operating System :: POSIX :: Linux',
        'Operating System :: MacOS',
        'Operating System :: Microsoft :: Windows :: Windows 10',
        'Programming Language :: C',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: Implementation :: CPython'
    ]
)
